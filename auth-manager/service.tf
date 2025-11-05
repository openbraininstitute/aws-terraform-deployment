locals {
  cpu    = 1024
  memory = 2048
}
data "aws_caller_identity" "current" {}

resource "aws_cloudwatch_log_group" "auth_manager_ecs_task_logs" {
  name_prefix       = "auth_manager"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })
}

resource "aws_ecs_cluster" "auth_manager" {
  name = "auth_manager_ecs_cluster"

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "auth_manager_ecs_task" {
  name_prefix = "auth_manager"
  vpc_id      = var.vpc_id
  description = "Sec group for auth_manager service"

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager_secgroup"
  })
}

resource "aws_vpc_security_group_ingress_rule" "auth_manager_allow_port_8000" {
  security_group_id = aws_security_group.auth_manager_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow port 8000 http"
}

resource "aws_vpc_security_group_ingress_rule" "auth_manager_allow_in_tcp" {
  security_group_id = aws_security_group.auth_manager_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "auth_manager_allow_outgoing_tcp" {
  security_group_id = aws_security_group.auth_manager_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "auth_manager_allow_outgoing_udp" {
  security_group_id = aws_security_group.auth_manager_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "auth_manager_ecs_definition" {
  family       = "auth_manager_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "auth_manager"
      family = "auth_manager"

      cpu    = local.cpu
      memory = local.memory

      networkMode = "awsvpc"

      image = var.image_url

      essential = true

      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "ROOT_PATH"
          value = var.root_path
        },
        {
          name  = "ENV"
          value = "prod"
        },
        {
          name  = "DEBUG"
          value = "false"
        },
        {
          name  = "CORS_ORIGINS"
          value = jsonencode(var.cors_origins)
        },
        {
          name  = "DATABASE_NAME"
          value = var.db_name
        },
        {
          name  = "DATABASE_USERNAME"
          value = var.db_username
        },
        {
          name  = "DATABASE_HOST"
          value = aws_db_instance.auth_manager.address
        },
        {
          name  = "KEYCLOAK_ISSUER"
          value = "https://${var.primary_domain}/auth"
        },
        {
          name  = "KEYCLOAK_CLIENT_ID"
          value = var.keycloak_client_id
        },
        {
          name  = "KEYCLOAK_CLIENT_UUID"
          value = var.keycloak_client_uuid
        },
        {
          name  = "KEYCLOAK_REALM"
          value = "SBO"
        },
        {
          name  = "KEYCLOAK_CONSENT_REDIRECT_URI"
          value = "https://${var.primary_domain}${var.root_path}/v1/offline-token/callback"
        },
        {
          name  = "KEYCLOAK_AFTER_CONSENT_REDIRECT_URI"
          value = "https://${var.primary_domain}/app/consent-feedback"
        },
        {
          name  = "ACK_STATE_EXPIRY"
          value = "${tostring(var.ack_state_expiry)}"
        },
      ]
      secrets = [
        {
          name      = "DATABASE_PASSWORD"
          valueFrom = "${var.auth_manager_secrets_arn}:DATABASE_PASSWORD::"
        },
        {
          name      = "KEYCLOAK_CLIENT_SECRET"
          valueFrom = "${var.auth_manager_secrets_arn}:KEYCLOAK_CLIENT_SECRET::"
        },
        {
          name      = "AUTH_MANAGER_TOKEN_VAULT_ENCRYPTION_KEY"
          valueFrom = "${var.auth_manager_secrets_arn}:AUTH_MANAGER_TOKEN_VAULT_ENCRYPTION_KEY::"
        },
        {
          name      = "ACK_STATE_SECRET"
          valueFrom = "${var.auth_manager_secrets_arn}:STATE_TOKEN_SECRET::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.auth_manager_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "auth_manager"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_auth_manager_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_auth_manager_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.auth_manager_ecs_task_logs,
  ]

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })
}

resource "aws_ecs_service" "auth_manager_ecs_service" {
  name            = "auth_manager_ecs_service"
  cluster         = aws_ecs_cluster.auth_manager.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.auth_manager_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.auth_manager_private_tg.arn
    container_name   = "auth_manager"
    container_port   = 8000
  }

  network_configuration {
    security_groups = [aws_security_group.auth_manager_ecs_task.id]
    subnets = [aws_subnet.auth_manager_ecs_a.id,
      aws_subnet.auth_manager_ecs_b.id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_auth_manager_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })
}

resource "aws_iam_role" "ecs_auth_manager_task_execution_role" {
  name_prefix = "auth_manager"

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

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })
}

resource "aws_iam_role_policy_attachment" "ecs_auth_manager_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_auth_manager_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_auth_manager_task_role" {
  name_prefix = "auth_manager"

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

  tags = merge(var.auth_manager_svc_tags, {
    Name = "auth_manager"
  })
}

resource "aws_iam_policy" "ecs_task_logs_auth_manager" {
  name_prefix = "auth_manager"
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
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.auth_manager_ecs_task_logs.name}*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_auth_manager_task_execution_role.name
  policy_arn = aws_iam_policy.auth_manager_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_auth_manager_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs_auth_manager.arn
}
