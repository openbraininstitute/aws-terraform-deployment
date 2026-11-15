# HAProxy keeps each page on one task (hash of the page id) so its changes skip Redis; only a speed-up.
# Limit: Cloud Map returns at most 8 records. Upgrade before 8 tasks: DiscoverInstances + HAProxy runtime API.

locals {
  router_container_name = "router"
  router_port           = 8080 # must match "bind :8080" in haproxy.cfg

  # The name the router looks up (LOGBOOK_TASKS in haproxy.cfg).
  tasks_dns_name = "${aws_service_discovery_service.logbook_tasks.name}.${aws_service_discovery_private_dns_namespace.logbook.name}"
}

resource "aws_service_discovery_private_dns_namespace" "logbook" {
  name        = "logbook.local"
  description = "Service discovery for the logbook server tasks (the page router resolves them)"
  vpc         = data.aws_vpc.main.id
}

# No custom health check (the server image has no shell); the router checks /readyz itself.
resource "aws_service_discovery_service" "logbook_tasks" {
  name = "tasks"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.logbook.id

    dns_records {
      ttl  = 10 # seconds; must match "hold valid 10s" in haproxy.cfg
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
    cpu_architecture        = "ARM64" # the router image is built for linux/arm64 only
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

      # Two file handles per WebSocket; maxconn 30000 in haproxy.cfg is sized to this.
      ulimits = [
        {
          name      = "nofile"
          softLimit = 65535
          hardLimit = 65535
        }
      ]

      # The ALB has drained the router by now; hard-stop-after 10s in haproxy.cfg ends the rest.
      stopTimeout = 15

      logConfiguration = merge(local.log_configuration, {
        options = merge(local.log_configuration.options, {
          awslogs-stream-prefix = "router"
        })
      })
    }
  ])

  # CPU grows with typing (0.5 vCPU maxed out at 200 busy pages, measured); 2 GB is the Fargate minimum for 1 vCPU.
  cpu    = 1024
  memory = 2048

  requires_compatibilities = ["FARGATE"]

  # Same role as the server (ECR pull, CloudWatch Logs); the router calls no AWS API.
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

  # Task subnets on purpose: the server trusts these ranges as proxies (SERVER_TRUSTED_PROXIES).
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

  # App Auto Scaling owns the router count.
  lifecycle {
    ignore_changes = [desired_count]
  }

  # All routers build the same hash ring, so a page keeps its task across a router deploy.
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
