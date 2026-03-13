locals {
  log_group_prefix = "ecs/small-scale-simulator"
  redis_task_size = {
    cpu    = 256
    memory = 512
  }
}

# TODO create via for-each loop
resource "aws_cloudwatch_log_group" "redis" {
  name              = "${local.log_group_prefix}/redis"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge({ Name = "small_scale_simulator_log_group_redis" }, var.tags)
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "${local.log_group_prefix}/api"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge({ Name = "small_scale_simulator_log_group_api" }, var.tags)
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "${local.log_group_prefix}/worker"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge({ Name = "small_scale_simulator_log_group_worker" }, var.tags)
}

resource "aws_ecs_cluster" "main" {
  name = "small-scale-simulator"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = merge({ Name = "small_scale_simulator_ecs_cluster" }, var.tags)
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE", "FARGATE_SPOT"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "small-scale-simulator-ecs"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_logs" {
  name_prefix = "small_scale_simulator_ecs"
  description = "Allows ECS tasks to create log streams and log groups in CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}

resource "aws_iam_role_policy_attachment" "efs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

# Task Role for API and Worker (needed for EFS IAM authorization)
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "small-scale-simulator-task"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_efs" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

# Policy to allow API service to push CloudWatch metrics
resource "aws_iam_policy" "api_cloudwatch_metrics" {
  name_prefix = "small-scale-simulator-api-metrics"
  description = "Policy to allow API service to push custom metrics to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "cloudwatch:namespace" = "SmallScaleSimulator/JobQueue"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_cloudwatch_metrics" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.api_cloudwatch_metrics.arn
}

# Service Discovery Namespace
resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "small-scale-simulator.local"
  description = "Service discovery namespace for small-scale-simulator"
  vpc         = data.aws_vpc.main.id
}

# Service Discovery Service for Redis
resource "aws_service_discovery_service" "redis" {
  name = "redis"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.main.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }
}

# Redis Task Definition
resource "aws_ecs_task_definition" "redis" {
  family                   = "small-scale-simulator-redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = local.redis_task_size.cpu
  memory = local.redis_task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "redis-data"
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name  = "redis"
      image = "redis:8-alpine"

      cpu    = local.redis_task_size.cpu
      memory = local.redis_task_size.memory

      readonlyRootFilesystem = true

      portMappings = [
        {
          containerPort = 6379
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "redis-data"
          containerPath = "/data"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.redis.name
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "small-scale-simulator"
        }
      }
    }
  ])
}

# API Task Definition
resource "aws_ecs_task_definition" "api" {
  family                   = "small-scale-simulator-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = var.api_task_size.cpu
  memory = var.api_task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  // TODO: Add this back once ARM image build is fixed
  # runtime_platform {
  #   operating_system_family = "LINUX"
  #   cpu_architecture        = "ARM64"
  # }

  volume {
    name = "storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.small_scale_simulator_storage.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.small_scale_simulator_storage_ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name  = "api"
      image = var.api_docker_image_url

      cpu    = var.api_task_size.cpu
      memory = var.api_task_size.memory

      readonlyRootFilesystem = true

      stopTimeout = 120

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "storage"
          containerPath = "/app/storage"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]
      environment = concat([
        {
          name  = "REDIS_URL"
          value = "redis://redis.small-scale-simulator.local:6379"
        },
        {
          name  = "DEBUG"
          value = "True"
        },
        {
          name  = "BASE_PATH"
          value = var.base_path
        },
        {
          name  = "CORS_ORIGINS"
          value = jsonencode(var.cors_origins)
        },
        {
          name  = "KC_SERVER_URI"
          value = var.keycloak_server_url
        },
        {
          name  = "KC_REALM_NAME"
          value = "SBO"
        },
        {
          name  = "DEPLOYMENT_ENV"
          value = var.deployment_env
        },
        {
          name  = "ENTITYCORE_URI"
          value = var.entitycore_url
        },
        {
          name  = "ACCOUNTING_BASE_URL"
          value = var.accounting_base_url
        },
        {
          name  = "METRICS_CLOUD_PROVIDER"
          value = "aws"
        },
        {
          name  = "METRICS_INTERVAL"
          value = "10"
        },
        {
          name  = "METRICS_AWS_REGION"
          value = var.aws_region
        }
      ], var.cors_origin_regex != null ? [{ name = "CORS_ORIGIN_REGEX", value = var.cors_origin_regex }] : [])

      secrets = [
        {
          name      = "KC_CLIENT_ID"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_ID::"
        },
        {
          name      = "KC_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_SECRET::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.secrets_arn}:SENTRY_DSN::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "small-scale-simulator"
        }
      }
    }
  ])
}

# Worker Task Definitions
resource "aws_ecs_task_definition" "worker" {
  for_each = var.daemon_workers

  family                   = "small-scale-simulator-worker-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = each.value.task_size.cpu
  memory = each.value.task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  volume {
    name = "storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.small_scale_simulator_storage.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.small_scale_simulator_storage_ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name  = "worker"
      image = var.worker_docker_image_url

      cpu    = each.value.task_size.cpu
      memory = each.value.task_size.memory

      # TODO investigate if we can enable it
      readonlyRootFilesystem = false

      stopTimeout = 120

      mountPoints = [
        {
          sourceVolume  = "storage"
          containerPath = "/app/storage"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]
      environment = [
        {
          name  = "QUEUES"
          value = join(" ", each.value.queues)
        },
        {
          name  = "NUM_WORKERS"
          value = tostring(each.value.num_workers_per_task)
        },
        {
          name  = "REDIS_URL"
          value = "redis://redis.small-scale-simulator.local:6379"
        },
        {
          name  = "DEBUG"
          value = "True"
        },
        {
          name  = "BASE_PATH"
          value = var.base_path
        },
        {
          name  = "KC_SERVER_URI"
          value = var.keycloak_server_url
        },
        {
          name  = "KC_REALM_NAME"
          value = "SBO"
        },
        {
          name  = "DEPLOYMENT_ENV"
          value = var.deployment_env
        },
        {
          name  = "ENTITYCORE_URI"
          value = var.entitycore_url
        },
        {
          name  = "ACCOUNTING_BASE_URL"
          value = var.accounting_base_url
        }
      ]

      secrets = [
        {
          name      = "KC_CLIENT_ID"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_ID::"
        },
        {
          name      = "KC_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_SECRET::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.secrets_arn}:SENTRY_DSN::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "small-scale-simulator"
        }
      }
    }
  ])
}


# ECS Services
resource "aws_ecs_service" "redis" {
  name            = "redis"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.redis.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [aws_security_group.redis.id]
    subnets         = [aws_subnet.small_scale_simulator_primary_a.id, aws_subnet.small_scale_simulator_primary_b.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  tags = merge({ Name = "small_scale_simulator_ecs_redis" }, var.tags)

  propagate_tags = "SERVICE"
}

resource "aws_ecs_service" "api" {
  name            = "api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [aws_security_group.api.id]
    subnets          = [aws_subnet.small_scale_simulator_primary_a.id, aws_subnet.small_scale_simulator_primary_b.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "api"
    container_port   = 8000
  }

  depends_on = [aws_ecs_service.redis]

  tags = merge({ Name = "small_scale_simulator_ecs_api" }, var.tags)

  propagate_tags = "SERVICE"
}

resource "aws_ecs_service" "worker" {
  for_each = var.daemon_workers

  name            = "worker-${each.key}"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker[each.key].arn
  desired_count   = each.value.num_worker_tasks

  # Ignore desired_count changes to allow autoscaling or manual adjustments
  lifecycle {
    ignore_changes = [desired_count]
  }

  dynamic "capacity_provider_strategy" {
    for_each = each.value.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = capacity_provider_strategy.value.weight
    }
  }

  network_configuration {
    security_groups = [aws_security_group.worker.id]
    subnets         = [aws_subnet.small_scale_simulator_secondary_a.id, aws_subnet.small_scale_simulator_secondary_b.id]
  }

  depends_on = [aws_ecs_service.redis]

  tags = merge({ Name = "small_scale_simulator_ecs_daemon_worker" }, var.tags)

  propagate_tags = "SERVICE"
}


# Auto Scaling Target for Worker Services
resource "aws_appautoscaling_target" "worker" {
  for_each = { for k, v in var.daemon_workers : k => v if v.autoscaler.enabled }

  max_capacity       = each.value.autoscaler.max_num_worker_tasks
  min_capacity       = each.value.num_worker_tasks
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.worker[each.key].name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  tags = merge({ Name = "small_scale_simulator_as_target" }, var.tags)
}

# Auto Scaling Policy for Worker Services (CPU-based)
resource "aws_appautoscaling_policy" "worker_cpu" {
  for_each = { for k, v in var.daemon_workers : k => v if v.autoscaler.enabled }

  name               = "small-scale-simulator-worker-${each.key}-cpu-scaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.worker[each.key].resource_id
  scalable_dimension = aws_appautoscaling_target.worker[each.key].scalable_dimension
  service_namespace  = aws_appautoscaling_target.worker[each.key].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = 80.0
    scale_in_cooldown  = 60
    scale_out_cooldown = 600
  }
}

# Batch Worker Task Definitions
resource "aws_ecs_task_definition" "batch_worker" {
  for_each = var.batch_workers

  family                   = "small-scale-simulator-batch-worker-${each.key}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = each.value.task_size.cpu
  memory = each.value.task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  volume {
    name = "storage"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.small_scale_simulator_storage.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.small_scale_simulator_storage_ap.id
        iam             = "ENABLED"
      }
    }
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name  = "worker"
      image = var.worker_docker_image_url

      cpu    = each.value.task_size.cpu
      memory = each.value.task_size.memory

      # TODO investigate if we can enable it
      readonlyRootFilesystem = false

      stopTimeout = 120

      mountPoints = [
        {
          sourceVolume  = "storage"
          containerPath = "/app/storage"
          readOnly      = false
        },
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]
      environment = [
        {
          name  = "QUEUES"
          value = join(" ", each.value.queues)
        },
        {
          name  = "NUM_WORKERS"
          value = tostring(each.value.num_workers_per_task)
        },
        {
          name  = "EXIT_AFTER_JOBS_COMPLETE"
          value = "True"
        },
        {
          name  = "REDIS_URL"
          value = "redis://redis.small-scale-simulator.local:6379"
        },
        {
          name  = "DEBUG"
          value = "True"
        },
        {
          name  = "BASE_PATH"
          value = var.base_path
        },
        {
          name  = "KC_SERVER_URI"
          value = var.keycloak_server_url
        },
        {
          name  = "KC_REALM_NAME"
          value = "SBO"
        },
        {
          name  = "DEPLOYMENT_ENV"
          value = var.deployment_env
        },
        {
          name  = "ENTITYCORE_URI"
          value = var.entitycore_url
        },
        {
          name  = "ACCOUNTING_BASE_URL"
          value = var.accounting_base_url
        }
      ]

      secrets = [
        {
          name      = "KC_CLIENT_ID"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_ID::"
        },
        {
          name      = "KC_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:KC_CLIENT_SECRET::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.secrets_arn}:SENTRY_DSN::"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.worker.name
          awslogs-create-group  = "true"
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "small-scale-simulator-on-demand"
        }
      }
    }
  ])

  tags = merge({ Name = "small_scale_simulator_ecs_batch_worker" }, var.tags)
}
