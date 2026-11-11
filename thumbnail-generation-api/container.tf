# Cluster Definition

resource "aws_ecs_cluster" "main" {
  name = "thumbnail_generation_api_cluster"

  tags = {
    Application = "thumbnail_generation_api"
    SBO_Billing = "thumbnail_generation_api"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "thumbnail_generation_api-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}


resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_task_role" {
  name = "thumbnail_generation_api-ecsTaskRole"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_iam_policy" "ecs_task_logs" {
  name        = "thumbnail_generation_api-ecsTaskLogs"
  description = "Allows ECS tasks to create log streams and log groups in CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:CreateLogGroup"
        ]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_log_role_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}


resource "aws_security_group" "main" {
  name        = "thumbnail_generation_api_sec_group"
  vpc_id      = var.vpc_id
  description = "Sec group for thumbnail generation api"

  tags = {
    Name        = "thumbnail_generation_api_secgroup"
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_port_80" {
  security_group_id = aws_security_group.main.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = var.vpc_cidr_block
  description = "Allow port 80 http"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outgoing_tcp" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all TCP"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "allow_outgoing_udp" {
  security_group_id = aws_security_group.main.id
  ip_protocol       = "udp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all UDP"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}


# Task: 2 vCPU / 4 GiB, all for the container (nginx + 2 app processes, one per vCPU).
# Every app setting is listed; .env.example in the service repo explains each one.
locals {
  task_cpu        = 2048
  task_memory_mib = 4096

  environment = {
    ENVIRONMENT = var.environment

    BASE_PATH             = var.base_path
    WHITELISTED_CORS_URLS = jsonencode(var.cors_origins)
    CORS_ORIGIN_REGEX     = var.cors_origin_regex # null: left out, app default

    ENTITY_CORE_URI              = var.entitycore_url
    ENTITY_CORE_TIMEOUT_SECONDS  = "30"
    ENTITY_CORE_DOWNLOAD_SECONDS = "60" # whole download, below nginx's 120 s
    ENTITY_CORE_MAX_CONNECTIONS  = "32"
    ENTITY_CORE_MAX_ASSET_BYTES  = null # left out: RENDER_MEMORY_BYTES / 3 (341 MiB), the most it may be

    RENDER_CONCURRENCY  = "4"
    RENDER_DOWNLOADS    = "16"
    RENDER_MEMORY_BYTES = tostring(1024 * 1024 * 1024) # per process: half the container for files

    SENTRY_DSN                  = "https://df67a83aab2f208467f94df08a207e59@o224246.ingest.us.sentry.io/4507457507885056"
    SENTRY_TRACES_SAMPLE_RATE   = "0.2"
    SENTRY_PROFILES_SAMPLE_RATE = "0.05"

    LOG_LEVEL  = "INFO"
    LOG_FORMAT = "JSON"
    LOG_DEBUG  = ""

    MPLCONFIGDIR = "/tmp/matplotlib" # /tmp is writable
  }
}

# Task Definition
resource "aws_ecs_task_definition" "main" {
  family                   = "thumbnail-generation-api-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  memory                   = local.task_memory_mib
  cpu                      = local.task_cpu

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "tmp"
  }

  volume {
    name = "var-cache-nginx"
  }

  volume {
    name = "var-run"
  }

  volume {
    name = "var-lib-nginx"
  }

  volume {
    name = "var-cache-fontconfig"
  }

  # Container definition for FastAPI
  container_definitions = jsonencode(
    [
      {
        name                   = "thumbnail-generation-api-container",
        image                  = var.docker_image_url,
        essential              = true,
        readonlyRootFilesystem = true,
        mountPoints = [
          {
            sourceVolume  = "tmp",
            containerPath = "/tmp"
          },
          {
            sourceVolume  = "var-cache-nginx",
            containerPath = "/var/cache/nginx"
          },
          {
            sourceVolume  = "var-cache-fontconfig",
            containerPath = "/var/cache/fontconfig"
          },
          {
            sourceVolume  = "var-run",
            containerPath = "/var/run"
          },
          {
            sourceVolume  = "var-lib-nginx",
            containerPath = "/var/lib/nginx"
          }
        ],
        portMappings = [
          {
            containerPort = 80,
            protocol      = "tcp"
          }
        ],
        environment = [for name, value in local.environment : { name = name, value = value } if value != null],
        # The whole task.
        memory = local.task_memory_mib
        cpu    = local.task_cpu
        logConfiguration = {
          logDriver = "awslogs"
          options = {
            awslogs-group         = var.log_group_name
            awslogs-region        = var.aws_region
            awslogs-create-group  = "true"
            awslogs-stream-prefix = "thumbnail_generation_api"
          }
        }

        linuxParameters = {
          initProcessEnabled = true
        }
      }
  ])
}

# Service
resource "aws_ecs_service" "service" {
  name                 = "thumbnail-generation-api-service"
  cluster              = aws_ecs_cluster.main.id
  task_definition      = aws_ecs_task_definition.main.arn
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"


  # Load Balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "thumbnail-generation-api-container"
    container_port   = 80
  }

  network_configuration {
    security_groups  = [aws_security_group.main.id]
    subnets          = [aws_subnet.main.id]
    assign_public_ip = false
  }

  propagate_tags = "SERVICE"
}

resource "aws_cloudwatch_log_group" "main" {
  name              = var.log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "thumbnail_generation_api"
    SBO_Billing = "thumbnail_generation_api"
  }
}

