locals {
  cpu    = 4096
  memory = 8192
}

resource "aws_cloudwatch_log_group" "bluenaas_ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "bluenaas_ecs"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name        = "bluenaas"
    SBO_Billing = "bluenaas"
  }
}

resource "aws_ecs_cluster" "bluenaas" {
  name = "bluenaas_ecs_cluster"

  tags = {
    Name        = "bluenaas"
    SBO_Billing = "bluenaas"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "bluenaas_ecs_task" {
  name_prefix = "bluenaas_ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for bluenaas service"

  tags = {
    Name        = "bluenaas_secgroup"
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bluenaas_allow_port_8000" {
  security_group_id = aws_security_group.bluenaas_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow port 8000 http"

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_ingress_rule" "bluenaas_allow_in_tcp" {
  security_group_id = aws_security_group.bluenaas_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_egress_rule" "bluenaas_allow_outgoing_tcp" {
  security_group_id = aws_security_group.bluenaas_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_egress_rule" "bluenaas_allow_outgoing_udp" {
  security_group_id = aws_security_group.bluenaas_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_ecs_task_definition" "bluenaas_ecs_definition" {
  family       = "bluenaas_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "bluenaas"
      family = "bluenaas"

      cpu    = local.cpu
      memory = local.memory

      networkMode = "awsvpc"

      image = var.docker_image_url

      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }

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
          value = "${var.debug}"
        },
        {
          name  = "BASE_PATH"
          value = "${var.base_path}"
        },
        {
          name  = "KC_SERVER_URI"
          value = "${var.keycloak_server_url}"
        },
        {
          name  = "KC_REALM_NAME"
          value = "SBO"
        },
        {
          name  = "DEPLOYMENT_ENV"
          value = "${var.deployment_env}"
        },
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
          awslogs-group         = aws_cloudwatch_log_group.bluenaas_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "bluenaas"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_bluenaas_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_bluenaas_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.bluenaas_ecs_task_logs,
  ]

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_ecs_service" "bluenaas_ecs_service" {
  name            = "bluenaas_ecs_service"
  cluster         = aws_ecs_cluster.bluenaas.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.bluenaas_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.bluenaas.arn
    container_name   = "bluenaas"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.bluenaas_ecs_task.id]
    subnets          = [aws_subnet.bluenaas_ecs_a.id, aws_subnet.bluenaas_ecs_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_bluenaas_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_iam_role" "ecs_bluenaas_task_execution_role" {
  name_prefix = "bluenaas_ecs"

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

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_bluenaas_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_bluenaas_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_bluenaas_task_role" {
  name_prefix = "bluenaas_ecs"

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

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_iam_policy" "ecs_task_logs_bluenaas" {
  name_prefix = "bluenaas_ecs"
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

resource "aws_iam_role_policy_attachment" "dockerhub" {
  role       = aws_iam_role.ecs_bluenaas_task_execution_role.name
  policy_arn = var.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_bluenaas_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_bluenaas_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs_bluenaas.arn
}
