locals {
  container_name = "logbook"
  container_port = 8080 # SERVER_PORT default of the image (apps/server/src/settings.ts)

  # Same image, run as an init container: `migrate` applies the Drizzle
  # migrations and exits. The server container starts only when it
  # exited 0 (dependsOn SUCCESS), so a task never runs code newer than
  # its schema. Every task start runs it; a Postgres advisory lock
  # (DATABASE_MIGRATION_LOCK_KEY) lets one migrator run at a time and a
  # second run is a no-op (the image smoke test migrates twice).
  migrate_container_name = "migrate"

  log_configuration = {
    logDriver = "awslogs"
    options = {
      awslogs-group         = aws_cloudwatch_log_group.logbook_ecs_task_logs.name
      awslogs-region        = var.aws_region
      awslogs-stream-prefix = "logbook"
    }
  }

  database_secret = {
    name      = "DATABASE_URL"
    valueFrom = "${aws_secretsmanager_secret.logbook_runtime.arn}:DATABASE_URL::"
  }
}

resource "aws_cloudwatch_log_group" "logbook_ecs_task_logs" {
  # The server writes JSON lines and CloudWatch embedded-metric lines on
  # stdout; CloudWatch turns the latter into metrics with no agent.
  name_prefix       = "logbook"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "logbook"
  }
}

resource "aws_ecs_cluster" "logbook" {
  name = "logbook_ecs_cluster"

  tags = {
    Name = "logbook"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_ecs_task_definition" "logbook_ecs_definition" {
  family       = "logbook_task_family"
  network_mode = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64" # release.yml builds linux/arm64 only
  }

  container_definitions = jsonencode([
    {
      name      = local.migrate_container_name
      image     = var.image_url
      essential = false
      command   = ["migrate"]

      secrets          = [local.database_secret]
      logConfiguration = local.log_configuration
    },
    {
      name = local.container_name

      image     = var.image_url
      essential = true

      dependsOn = [
        {
          containerName = local.migrate_container_name
          condition     = "SUCCESS"
        }
      ]

      portMappings = [
        {
          hostPort      = local.container_port
          containerPort = local.container_port
          protocol      = "tcp"
        }
      ]

      # The server's stop phases take at most 35 s (Postgres and Redis
      # both away; apps/server/src/core/shutdown.ts), past the ECS
      # default of 30 s, after which ECS kills the task and unsaved edits
      # are lost. 40 s is the value the server repo asks for; Fargate
      # allows up to 120 s. Raise it with any stop setting below.
      stopTimeout = 40

      # Only what differs from the image defaults; each default and its
      # reason is in apps/server/.env.example of the log-book repo.
      environment = [
        {
          name  = "SERVER_PORT"
          value = tostring(local.container_port)
        },
        {
          name  = "SERVER_BASE_PATH"
          value = var.base_path
        },
        {
          name  = "SERVER_ALLOWED_ORIGINS" # CORS, and the Origin check of the WebSocket upgrade
          value = join(",", var.allowed_origins)
        },
        {
          # Trusted proxy list (log-book apps/server/src/core/client-ip.ts):
          # the client IP is the first X-Forwarded-For entry, from the right,
          # outside these ranges. A browser comes through Azure Front Door,
          # the Azure Application Gateway (Private Link, then the VPN to the
          # private NLB, which keeps the source address) and the private ALB;
          # an agent in the VPC through the ALB alone. A hop count fits only
          # one of the two chains: with 1 every browser showed the gateway's
          # address and all of them shared one per-IP upgrade limit
          # (RATE_LIMIT_UPGRADE_PER_MINUTE), which a deploy's reconnect wave
          # would hit. Needs a server image with SERVER_TRUSTED_PROXIES
          # (log-book branch bmedd/trusted-proxies); an older image ignores it
          # and uses the socket address (the ALB) for everyone.
          # Page requests come through one more hop, the page router
          # (router.tf), which runs in the task subnets: they are added
          # here. Without them every browser would show the router's
          # address and share one upgrade limit.
          name  = "SERVER_TRUSTED_PROXIES"
          value = join(",", concat(var.trusted_proxy_cidr_blocks, [var.ecs_cidr_block_a, var.ecs_cidr_block_b]))
        },
        {
          name  = "SERVER_TIMING_ENABLED" # Server-Timing shows internal timings to clients
          value = tostring(var.server_timing_enabled)
        },
        {
          # Load shedding (admission control, log-book deployment.md 6.4): a
          # task whose event loop runs this late (median, ms) for 3 s refuses
          # new sockets, joins and agent writes with 503 and Retry-After, so
          # the people already on it keep working. The image default 0 never
          # refuses; an image without load shedding ignores it.
          name  = "LIVE_SHED_LOOP_DELAY_MS"
          value = tostring(var.shed_loop_delay_ms)
        },
        {
          name  = "REDIS_URL" # no AUTH token on this node, so nothing secret in it
          value = "redis://${aws_elasticache_cluster.logbook.cache_nodes[0].address}:${aws_elasticache_cluster.logbook.port}"
        },
        {
          name  = "KEYCLOAK_ISSUER"
          value = var.keycloak_issuer
        },
        {
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
        },
      ]

      secrets = [local.database_secret]

      logConfiguration = local.log_configuration

      linuxParameters = {
        initProcessEnabled = true
      }
    }
  ])

  cpu    = var.task_size.cpu
  memory = var.task_size.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_logbook_task_execution_role.arn
  # No task role: the server calls no AWS API (logs and metrics go
  # through stdout and the execution role's log driver).
}

resource "aws_ecs_service" "logbook_ecs_service" {
  name            = "logbook_ecs_service"
  cluster         = aws_ecs_cluster.logbook.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.logbook_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.logbook_private_tg.arn
    container_name   = local.container_name
    container_port   = local.container_port
  }

  # Each task's IP in Cloud Map DNS (tasks.logbook.local), what the page
  # router resolves (router.tf). The load_balancer block above stays: the
  # tasks keep their target group, its /healthz checks, its draining and
  # the circuit breaker, and the ALB still serves every path that is not
  # a page's. ECS removes a stopping task from DNS when it deregisters it.
  service_registries {
    registry_arn = aws_service_discovery_service.logbook_tasks.arn
  }

  network_configuration {
    security_groups = [aws_security_group.logbook_ecs_task.id]
    subnets = [
      aws_subnet.logbook_ecs_a.id,
      aws_subnet.logbook_ecs_b.id,
    ]
    assign_public_ip = false
  }

  force_new_deployment = true
  desired_count        = var.desired_count # applies at create only: App Auto Scaling owns the count (autoscaling.tf)

  lifecycle {
    ignore_changes = [desired_count]
  }

  # Rolling deploy: new tasks start before old ones stop, so live editing
  # never has zero tasks. Each task holds 14 Postgres connections and its
  # start runs one migrator connection, so a deploy at 200 % at the most
  # tasks needs 2 x max_count x 14 + max_count below the instance's
  # max_connections (log-book apps/server/README.md; the thresholds to
  # move the class are in the tfvars).
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # A task that never turns healthy (bad image, failed migration) stops
  # the deploy and rolls back to the last good task definition, instead
  # of replacing tasks for ever.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # ignore ALB health check failures for a grace period: the init
  # container runs the migrations before the server starts
  health_check_grace_period_seconds = 120

  propagate_tags = "SERVICE"

  depends_on = [
    aws_iam_role_policy_attachment.ecs_logbook_task_execution_role_policy_attachment,
    aws_iam_role_policy_attachment.secrets,
  ]
}

resource "aws_iam_role" "ecs_logbook_task_execution_role" {
  name_prefix = "logbook"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = { Service = "ecs-tasks.amazonaws.com" }
        Effect    = "Allow"
      }
    ]
  })
}

# ECR pull and CloudWatch Logs writes. A cross-account ECR repository
# must also grant this account in its own repository policy.
resource "aws_iam_role_policy_attachment" "ecs_logbook_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
