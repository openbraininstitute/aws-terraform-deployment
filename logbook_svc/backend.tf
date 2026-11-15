locals {
  container_name = "logbook"
  container_port = 8080 # the image's SERVER_PORT default

  # Runs first and updates the schema, so a task never runs code newer than its database.
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
  # CloudWatch turns the server's metric lines in these logs into metrics, so no agent is needed.
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
    cpu_architecture        = "ARM64" # the image is built for linux/arm64 only
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

      # Shutdown can take 35 s; the 30 s default would kill the task and lose unsaved edits.
      stopTimeout = 40

      # Only the values that differ from the image defaults.
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
          name  = "SERVER_ALLOWED_ORIGINS" # CORS and the WebSocket Origin check
          value = join(",", var.allowed_origins)
        },
        {
          # The task subnets are trusted too, because the page router adds a hop; else every browser shares its IP.
          name  = "SERVER_TRUSTED_PROXIES"
          value = join(",", concat(var.trusted_proxy_cidr_blocks, [var.ecs_cidr_block_a, var.ecs_cidr_block_b]))
        },
        {
          name  = "SERVER_TIMING_ENABLED" # Server-Timing shows internal timings to clients
          value = tostring(var.server_timing_enabled)
        },
        {
          name  = "COLLABORATION_SHED_LOOP_DELAY_MS"
          value = tostring(var.shed_loop_delay_ms)
        },
        {
          # Must match: the router image of the same version, since older routers ignore "draining".
          name  = "COLLABORATION_HAND_OFF_BUSY_PCT"
          value = tostring(var.hand_off_busy_pct)
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
  # No task role: the server calls no AWS API.
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

  # Lists each task in Cloud Map DNS so the page router can find it; the ALB still serves the rest.
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
  desired_count        = var.desired_count # applies at create only: App Auto Scaling owns the count

  lifecycle {
    ignore_changes = [desired_count]
  }

  # New tasks start before old ones stop, so editing never drops out.
  # Limit: a deploy needs 2 x max_count x 14 + max_count database connections. Upgrade: a bigger database class.
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  # A task that never gets healthy rolls the deploy back instead of retrying forever.
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # Room for the migrations to run before the server answers health checks.
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

# A cross-account ECR repository must also allow this account in its own policy.
resource "aws_iam_role_policy_attachment" "ecs_logbook_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
