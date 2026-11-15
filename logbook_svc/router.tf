# The page router (log-book apps/router: HAProxy). Page affinity: every
# request of one page goes to the same server task (consistent hashing on
# the page id in the path, log-book deployment.md 6.1). Without it the ALB
# spreads a page's people round robin over every task: each task loads the
# page, and every change crosses the Redis relay to all of them.
#
# ALB (page paths only, alb.tf) -> router tasks -> server tasks, found
# through Cloud Map DNS (tasks.logbook.local: one A record per task).
# Affinity only speeds things up: the Redis relay stays, so a split page
# (a task joined or left, two routers that disagree for a moment, every
# task failing the router's check) works as it does without the router.
#
# Ceiling: a Cloud Map multivalue answer holds at most 8 healthy records,
# so past 8 server tasks a router sees 8 of them and the ring churns. Next
# step before desired_count passes 8: a poller of Cloud Map
# DiscoverInstances that sets the servers through the HAProxy runtime API.

locals {
  router_container_name = "router"
  router_port           = 8080 # bind :8080 in apps/router/haproxy.cfg

  # What the router resolves (LOGBOOK_TASKS in haproxy.cfg).
  tasks_dns_name = "${aws_service_discovery_service.logbook_tasks.name}.${aws_service_discovery_private_dns_namespace.logbook.name}"
}

resource "aws_service_discovery_private_dns_namespace" "logbook" {
  name        = "logbook.local"
  description = "Service discovery for the logbook server tasks (the page router resolves them)"
  vpc         = data.aws_vpc.main.id
}

# ECS registers each server task here when it starts and removes it when
# it stops (service_registries in backend.tf). No health_check_custom_config:
# the server has no container health check to report (distroless, no
# shell); the router checks /readyz itself and drops a stopping task
# within about 3 s.
resource "aws_service_discovery_service" "logbook_tasks" {
  name = "tasks"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.logbook.id

    dns_records {
      ttl  = 10 # seconds; "hold valid 10s" in haproxy.cfg
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

resource "aws_ecs_task_definition" "logbook_router" {
  family       = "logbook_router_task_family"
  network_mode = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64" # release.yml builds linux/arm64 only
  }

  container_definitions = jsonencode([
    {
      name      = local.router_container_name
      image     = var.router_image_url
      essential = true

      portMappings = [
        {
          hostPort      = local.router_port
          containerPort = local.router_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "LOGBOOK_TASKS"
          value = "${local.tasks_dns_name}:${local.container_port}"
        },
      ]

      # Each open WebSocket holds two descriptors (browser side and task
      # side): haproxy.cfg's maxconn 30000 is sized to this limit.
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65535
          hardLimit = 65535
        }
      ]

      # The ALB has drained the router (deregistration_delay) before the
      # stop; haproxy.cfg's hard-stop-after 10s ends what is left.
      stopTimeout = 15

      logConfiguration = merge(local.log_configuration, {
        options = merge(local.log_configuration.options, {
          awslogs-stream-prefix = "router"
        })
      })
    }
  ])

  # 1 vCPU / 2 GB. Every socket frame of a page passes the router, so its
  # CPU grows with the typing, not with the tunnels: measured (log-book
  # deployment.md 6.8), about 0.5 core per 100 busy pages over all routers.
  # At 0.5 vCPU two routers hit their quota at 200 busy pages and became
  # the limit before the server tasks (propagation p95 3.6 s at 300 pages,
  # 0.7 s at 1 vCPU). Memory: at most 87 MB measured; 2 GB is the
  # smallest Fargate size with 1 vCPU.
  cpu    = 1024
  memory = 2048

  requires_compatibilities = ["FARGATE"]

  # ECR pull and CloudWatch Logs, as the server's; the router calls no AWS API.
  execution_role_arn = aws_iam_role.ecs_logbook_task_execution_role.arn
}

resource "aws_ecs_service" "logbook_router" {
  name            = "logbook_router_ecs_service"
  cluster         = aws_ecs_cluster.logbook.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.logbook_router.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.logbook_router_tg.arn
    container_name   = local.router_container_name
    container_port   = local.router_port
  }

  # In the task subnets: those ranges are the server's trusted proxies
  # (SERVER_TRUSTED_PROXIES, backend.tf).
  network_configuration {
    security_groups = [aws_security_group.logbook_router.id]
    subnets = [
      aws_subnet.logbook_ecs_a.id,
      aws_subnet.logbook_ecs_b.id,
    ]
    assign_public_ip = false
  }

  force_new_deployment = true
  desired_count        = var.router_desired_count

  # App Auto Scaling owns the router count too (autoscaling.tf).
  lifecycle {
    ignore_changes = [desired_count]
  }

  # Rolling deploy: a new router takes traffic before an old one stops.
  # Every router builds the same ring (hash-key addr), so a page keeps
  # its task across a router deploy.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # HAProxy answers /routerz as soon as it listens.
  health_check_grace_period_seconds = 30

  propagate_tags = "SERVICE"

  depends_on = [
    aws_iam_role_policy_attachment.ecs_logbook_task_execution_role_policy_attachment,
  ]
}
