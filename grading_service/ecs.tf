locals {
  log_group_prefix = "ecs/grading-service"
  redis_task_size = {
    cpu    = 256
    memory = 512
  }
  api_task_size = {
    cpu    = 256
    memory = 512
  }
}

# Log Groups

resource "aws_cloudwatch_log_group" "redis" {
  name              = "${local.log_group_prefix}/redis"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge({ Name = "grading_service_log_group_redis" }, var.tags)
}

resource "aws_cloudwatch_log_group" "api" {
  name              = "${local.log_group_prefix}/api"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge({ Name = "grading_service_log_group_api" }, var.tags)
}

# ECS Cluster

resource "aws_ecs_cluster" "main" {
  name = "grading-service"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }

  tags = merge({ Name = "grading_service_ecs_cluster" }, var.tags)
}

resource "aws_ecs_cluster_capacity_providers" "main" {
  cluster_name = aws_ecs_cluster.main.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

# IAM Roles

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "grading_service"

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
  name_prefix = "grading_service_ecs"
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

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}

resource "aws_iam_role_policy_attachment" "execution_efs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}

# Task Role (needed for EFS IAM authorization)
resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "grading-service-task"

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

# Service Discovery

resource "aws_service_discovery_private_dns_namespace" "main" {
  name        = "grading-service.local"
  description = "Service discovery namespace for grading-service"
  vpc         = data.aws_vpc.main.id
}

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
  family                   = "grading-service-redis"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = local.redis_task_size.cpu
  memory = local.redis_task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "redis-data"

    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.redis_data.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.redis_data.id
        iam             = "ENABLED"
      }
    }
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

      command = [
        "redis-server",
        "--appendonly", "yes",
        "--auto-aof-rewrite-percentage", "100",
        "--auto-aof-rewrite-min-size", "64mb"
      ]

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
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "grading-service"
        }
      }
    }
  ])
}

# API Task Definition

resource "aws_ecs_task_definition" "api" {
  family                   = "grading-service-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  cpu    = local.api_task_size.cpu
  memory = local.api_task_size.memory

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      name  = "api"
      image = var.docker_image_url

      cpu    = local.api_task_size.cpu
      memory = local.api_task_size.memory

      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "REDIS_URL"
          value = "redis://redis.grading-service.local:6379"
        },
        {
          name  = "BASE_PATH"
          value = var.base_path
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "grading-service"
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
    subnets         = [aws_subnet.grading_service_a.id, aws_subnet.grading_service_b.id]
  }

  service_registries {
    registry_arn = aws_service_discovery_service.redis.arn
  }

  tags = merge({ Name = "grading_service_ecs_redis" }, var.tags)

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
    subnets          = [aws_subnet.grading_service_a.id, aws_subnet.grading_service_b.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "api"
    container_port   = 8000
  }

  depends_on = [aws_ecs_service.redis]

  tags = merge({ Name = "grading_service_ecs_api" }, var.tags)

  propagate_tags = "SERVICE"
}
