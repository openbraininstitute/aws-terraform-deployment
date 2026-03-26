locals {
  api_container_name = "main"
  api_container_port = 8000
}

resource "aws_cloudwatch_log_group" "api" {
  # TODO check if the logs can be encrypted
  name_prefix       = "launch_system_api"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Name = "launch_system_api" })
}

resource "aws_ecs_cluster" "api" {
  name = "launch_system_api"

  tags = merge(var.tags, { Name = "launch_system_api" })


  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "api" {
  name_prefix = "launch_system_api"
  vpc_id      = var.vpc_id
  description = "Sec group for launch system api"

  tags = merge(var.tags, { Name = "launch_system_api" })
}

resource "aws_vpc_security_group_ingress_rule" "api_allow_port_8000" {
  security_group_id = aws_security_group.api.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow port 8000 http"
}

resource "aws_vpc_security_group_egress_rule" "api_allow_outgoing_tcp" {
  security_group_id = aws_security_group.api.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "api_allow_outgoing_udp" {
  security_group_id = aws_security_group.api.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "api" {
  family       = "launch_system_api_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name = local.api_container_name

      cpu    = var.api_task_size.cpu
      memory = var.api_task_size.memory

      networkMode = "awsvpc"

      image = var.api_image_url

      essential = true

      readonlyRootFilesystem = true

      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]

      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: add a proper health check.
        interval    = 60
        timeout     = 5
        startPeriod = 30
        retries     = 3
      }

      environment = [
        {
          name  = "PYTHONDONTWRITEBYTECODE"
          value = "1"
        },
        {
          name  = "APP_DEBUG"
          value = "false"
        },
        {
          name  = "CORS_ORIGINS"
          value = jsonencode(var.cors_origins)
        },
        {
          name  = "KEYCLOAK_URL"
          value = var.keycloak_url
        },
        {
          name  = "ROOT_PATH"
          value = var.root_path
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_NAME"
          value = var.db_name
        },
        {
          name  = "DB_USER"
          value = var.db_username
        },
        {
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
        },
        {
          name  = "AUTH_MANAGER_URL"
          value = var.auth_manager_url
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_cluster.redis.cache_nodes[0].address
        },
        {
          name  = "REDIS_PORT"
          value = tostring(aws_elasticache_cluster.redis.port)
        },
        {
          name  = "REDIS_URL" # deprecated, use REDIS_HOST and REDIS_PORT
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}/0"
        },
        {
          name  = "CODEARTIFACT_CONFIG"
          value = jsonencode(var.codeartifact_config)
        }
      ]

      secrets = [
        {
          name      = "DB_PASS"
          valueFrom = "${var.secrets_arn}:DB_PASS::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.api.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "launch_system_api"
        }
      }
    }
  ])

  cpu    = var.api_task_size.cpu
  memory = var.api_task_size.memory

  volume {
    name = "tmp"
  }

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.api_execution.arn
  task_role_arn      = aws_iam_role.api_task.arn

  depends_on = [
    aws_cloudwatch_log_group.api,
  ]
}

resource "aws_ecs_service" "api" {
  name            = "launch_system_api"
  cluster         = aws_ecs_cluster.api.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.api.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.private.arn
    container_name   = local.api_container_name
    container_port   = local.api_container_port
  }

  network_configuration {
    security_groups = [aws_security_group.api.id]
    subnets = [
      aws_subnet.trusted_a.id,
      aws_subnet.trusted_b.id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.api_execution,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "api_execution" {
  name_prefix = "launch_system_api"

  assume_role_policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOT
}

resource "aws_iam_role_policy_attachment" "api_execution" {
  role       = aws_iam_role.api_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "api_task" {
  name_prefix = "launch_system_api"

  assume_role_policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOT
}

resource "aws_iam_policy" "api_logs_access" {
  name_prefix = "launch_system_api"
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

resource "aws_iam_role_policy_attachment" "api_secrets_access" {
  role       = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_policy" "api_codeartifact_read" {
  name_prefix = "launch_system_api_codeartifact"
  description = "Allow the launch system API task to pull packages from CodeArtifact"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "sts:GetServiceBearerToken",
          "codeartifact:GetAuthorizationToken",
          "codeartifact:GetRepositoryEndpoint",
          "codeartifact:ReadFromRepository",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_codeartifact_read" {
  role       = aws_iam_role.api_task.name
  policy_arn = aws_iam_policy.api_codeartifact_read.arn
}

resource "aws_iam_role_policy_attachment" "api_logs_access" {
  role       = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.api_logs_access.arn
}
