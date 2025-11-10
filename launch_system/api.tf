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
      name   = "launch_system_api"
      family = "launch_system_api"

      cpu    = var.api_task_size.cpu
      memory = var.api_task_size.memory

      networkMode = "awsvpc"

      image = var.api_image_url

      essential = true

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
          name  = "AZ_REGION"
          value = var.az_region
        },
        {
          name  = "TOKEN_LIFETIME_EXTENSION_INTERVAL"
          value = var.token_lifetime_extension_interval
        },
        {
          name  = "TOKEN_LIFETIME_SKIP"
          value = "True"
        },
        {
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
        },
        {
          name  = "LAUNCH_SYSTEM_API_URL"
          value = var.launch_system_api_url
        },
        {
          name  = "LAUNCH_SERVER_URL" # for backward compatibility
          value = var.launch_system_api_url
        },
        {
          name  = "KEYCLOAK_CLIENT_ID"
          value = var.keycloak_client_id
        },
        {
          name  = "SIMULATION_LAUNCH_COMMAND"
          value = var.simulation_launch_command
        },
        # currently token refresh is disabled;
        {
          name  = "KEYCLOAK_CLIENT_SECRET"
          value = ""
        },
      ]

      secrets = [
        {
          name      = "DB_PASS"
          valueFrom = "${var.secrets_arn}:DB_PASS::"
        },
        {
          name      = "AZURE_CLIENT_ID"
          valueFrom = "${var.secrets_arn}:AZURE_CLIENT_ID::"
        },
        {
          name      = "AZURE_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:AZURE_CLIENT_SECRET::"
        },
        {
          name      = "AZURE_TENANT_ID"
          valueFrom = "${var.secrets_arn}:AZURE_TENANT_ID::"
        },
        {
          name      = "AZ_SUBSCRIPTION_ID"
          valueFrom = "${var.secrets_arn}:AZ_SUBSCRIPTION_ID::"
        },
        {
          name      = "AZ_BATCH_ACCOUNT_NAME"
          valueFrom = "${var.secrets_arn}:AZ_BATCH_ACCOUNT_NAME::"
        },
        {
          name      = "AZ_BATCH_POOL_NAME"
          valueFrom = "${var.secrets_arn}:AZ_BATCH_POOL_NAME::"
        },
        {
          name      = "AZ_UPLOAD_BLOB_SAS_URL"
          valueFrom = "${var.secrets_arn}:AZ_UPLOAD_BLOB_SAS_URL::"
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
    container_name   = "launch_system_api"
    container_port   = 8000
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

resource "aws_iam_policy" "ecs_task_logs_launch" {
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

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.api_execution.name
  policy_arn = aws_iam_policy.ecs_task_logs_launch.arn
}
