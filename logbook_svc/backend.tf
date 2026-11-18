locals {
  container_name = "logbook"
  container_port = 8080

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

  keycloak_service_secret = {
    name      = "KEYCLOAK_SERVICE_CLIENT_SECRET"
    valueFrom = "${aws_secretsmanager_secret.logbook_runtime.arn}:KEYCLOAK_SERVICE_CLIENT_SECRET::"
  }


  server_environment = {
    SERVER_PORT                   = local.container_port
    SERVER_BASE_PATH              = var.base_path
    SERVER_ALLOWED_ORIGINS        = join(",", var.allowed_origins)                                                                 # CORS and the WebSocket Origin check
    SERVER_ENVIRONMENT            = "production"                                                                                   # staging too: only "development" pushes metrics to a local CloudWatch
    SERVER_TRUSTED_PROXIES        = join(",", concat(var.trusted_proxy_cidr_blocks, [var.ecs_cidr_block_a, var.ecs_cidr_block_b])) # the router subnets too, or every browser shares its IP
    SERVER_DRAIN_DELAY_MS         = 5000                                                                                           # must stay above the router's 3 s to mark a stopping task down
    SERVER_READY_PROBE_TIMEOUT_MS = 1000
    SERVER_TIMING_ENABLED         = var.server_timing_enabled
    SERVER_OPENAPI_ENABLED        = true

    DATABASE_POOL_MAX                       = 10
    DATABASE_STATEMENT_TIMEOUT_MS           = 5000
    DATABASE_LOCK_TIMEOUT_MS                = 2000
    DATABASE_IDLE_IN_TRANSACTION_TIMEOUT_MS = 10000
    DATABASE_MIGRATION_LOCK_KEY             = "logbook:migrate"

    REDIS_URL                       = "redis://${aws_elasticache_cluster.logbook.cache_nodes[0].address}:${aws_elasticache_cluster.logbook.port}"
    REDIS_MAX_RETRIES_PER_REQUEST   = 1
    REDIS_CONNECT_TIMEOUT_MS        = 10000
    REDIS_COMMAND_TIMEOUT_MS        = 2000
    REDIS_RELAY_DISCONNECT_DELAY_MS = 50

    KEYCLOAK_ISSUER            = var.keycloak_issuer
    KEYCLOAK_CALL_TIMEOUT_MS   = 3000
    KEYCLOAK_SERVICE_CLIENT_ID = "logbook-server"

    ENTITYCORE_URL                  = var.entitycore_url
    ENTITYCORE_CALL_TIMEOUT_MS      = 3000
    ENTITYCORE_IMPORT_ENABLED       = false
    ENTITYCORE_IMPORT_MAX_BYTES     = 1048576
    ENTITYCORE_MAX_CONCURRENT_CALLS = 10
    ENTITYCORE_MAX_QUEUED_CALLS     = 100
    ENTITYCORE_PAUSE_AFTER_FAILURES = 5
    ENTITYCORE_FAILURE_WINDOW_MS    = 30000
    ENTITYCORE_PAUSE_MS             = 15000

    AUTH_PERMISSION_TTL_S = 300
    AUTH_USERINFO_TTL_S   = 300
    AUTH_ACTOR_CACHE_SIZE = 10000

    IDEMPOTENCY_TTL_H              = 24
    IDEMPOTENCY_LOCK_TIMEOUT_MS    = 2000
    IDEMPOTENCY_CLEANUP_BATCH_SIZE = 1000

    REQUEST_LOG_BATCH_SIZE        = 500
    REQUEST_LOG_FLUSH_INTERVAL_MS = 1000
    REQUEST_LOG_BUFFER_CAP        = 10000
    REQUEST_LOG_RETENTION_DAYS    = 90
    REQUEST_LOG_RETRY_MIN_MS      = 100
    REQUEST_LOG_RETRY_MAX_MS      = 2000
    REQUEST_LOG_STOP_FLUSH_MS     = 2000

    STORE_FLUSH_INTERVAL_MS  = 1000
    STORE_UNSAVED_MAX_BYTES  = 8388608
    STORE_RETRY_MIN_MS       = 100
    STORE_RETRY_MAX_MS       = 2000
    STORE_ROW_MAX_UPDATES    = 200
    STORE_ROW_MAX_BYTES      = 1048576
    STORE_FLUSHED_TIMEOUT_MS = 5000
    STORE_STOP_DEADLINE_MS   = 10000 # the whole stop must fit in stopTimeout (40 s)
    STORE_REPAIR_INTERVAL_MS = 60000

    MERGE_MAX_UPDATES    = 200
    MERGE_MAX_BYTES      = 262144
    MERGE_SNAPSHOT_SHARE = 0.1
    MERGE_PAGE_MAX_BYTES = 8388608
    MERGE_CONCURRENCY    = 2

    # sync pages to entitycore, signed in as the Keycloak client logbook-server (entitycore admin)
    ENTITYCORE_SYNC_ENABLED           = true
    ENTITYCORE_SYNC_QUIET_S           = 120
    ENTITYCORE_SYNC_DEADLINE_S        = 900
    ENTITYCORE_SYNC_LEAVE_GRACE_S     = 30
    ENTITYCORE_SYNC_SWEEP_BATCH       = 100
    ENTITYCORE_SYNC_BACKOFF_MAX_S     = 3600
    ENTITYCORE_SYNC_LEASE_S           = 120
    ENTITYCORE_SYNC_UPLOAD_TIMEOUT_MS = 30000

    WORKERS_YJS_POOL_SIZE          = 1
    WORKERS_YJS_INLINE_MAX_BYTES   = 16384
    WORKERS_YJS_COMPACT_TIMEOUT_MS = 30000
    WORKERS_YJS_QUEUE_MAX          = 16

    COLLABORATION_IDLE_TIMEOUT_S           = 120 # the router's tunnel timeout (600 s) must stay above it
    COLLABORATION_MAX_PAYLOAD_BYTES        = 1048576
    COLLABORATION_BACKPRESSURE_LIMIT_BYTES = 25165824
    COLLABORATION_TOKEN_REFRESH_LEAD_S     = 30
    COLLABORATION_BROADCAST_DELAY_MS       = 100
    COLLABORATION_UNLOAD_WAIT_MS           = 2000
    COLLABORATION_PEERS_TTL_S              = 86400
    COLLABORATION_TASK_ALIVE_TTL_S         = 30
    COLLABORATION_MAX_REFUSED_JOINS        = 10
    COLLABORATION_SHED_LOOP_DELAY_MS       = var.shed_loop_delay_ms
    COLLABORATION_SHED_HOLD_MS             = 10000
    COLLABORATION_HAND_OFF_BUSY_PCT        = var.hand_off_busy_pct # needs the router image of the same version

    DOC_CHANGE_MAX_BYTES = 1048576
    DOC_PRESENCE_TTL_S   = 30

    RATE_LIMIT_READ_PER_MINUTE        = 600
    RATE_LIMIT_WRITE_PER_MINUTE       = 300
    RATE_LIMIT_UPGRADE_PER_MINUTE     = 240
    RATE_LIMIT_TOKEN_CHECK_PER_MINUTE = 120

    JOBS_POOL_MAX             = 3
    JOBS_POLL_INTERVAL_S      = 5
    JOBS_CONCURRENCY          = 1
    JOBS_SUPERVISE_INTERVAL_S = 60
    JOBS_START_RETRY_MIN_MS   = 1000
    JOBS_START_RETRY_MAX_MS   = 30000
    JOBS_STOP_WAIT_MS         = 5000

    TELEMETRY_METRICS_FLUSH_MS   = 10000
    TELEMETRY_METRICS_MAX_VALUES = 100
    LOG_LEVEL                    = "info"
    LOG_FORMAT                   = "json"
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
    cpu_architecture        = "ARM64"
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
      environment = [for name, value in local.server_environment : { name = name, value = tostring(value) }]

      secrets = [local.database_secret, local.keycloak_service_secret]

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

  # lists each task in Cloud Map DNS so the page router can find it; 
  # the ALB still serves the rest
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


  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  # room for the migrations to run before the server answers health checks.
  health_check_grace_period_seconds = 120

  propagate_tags = "SERVICE"

  depends_on = [
    aws_iam_role_policy_attachment.ecs_logbook_task_execution_role_policy_attachment,
    aws_iam_role_policy_attachment.secrets,
  ]
}

resource "aws_iam_role" "ecs_logbook_task_execution_role" {
  name = "logbook_service"

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


resource "aws_iam_role_policy_attachment" "ecs_logbook_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_logbook_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
