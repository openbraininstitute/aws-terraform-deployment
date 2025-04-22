locals {
  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "obi_generative_gui_ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "obi_generative_gui_ecs"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "obi_generative_gui"
  }
}

resource "aws_ecs_cluster" "obi_generative_gui" {
  name = "obi_generative_gui_ecs_cluster"

  tags = {
    Name = "obi_generative_gui"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "obi_generative_gui_ecs_task" {
  name_prefix = "obi_generative_gui_ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for obi-generative-gui service"

  tags = {
    Name = "obi_generative_gui_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "obi_generative_gui_allow_port_8000" {
  security_group_id = aws_security_group.obi_generative_gui_ecs_task.id

  ip_protocol = "tcp"
  from_port   = var.container_port
  to_port     = var.container_port
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow access to the container port"
}

resource "aws_vpc_security_group_egress_rule" "obi_generative_gui_allow_outgoing_tcp" {
  security_group_id = aws_security_group.obi_generative_gui_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "obi_generative_gui_allow_outgoing_udp" {
  security_group_id = aws_security_group.obi_generative_gui_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "obi_generative_gui_ecs_definition" {
  family       = "obi_generative_gui_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "obi_generative_gui"
      family = "obi_generative_gui"

      cpu    = local.cpu
      memory = local.memory

      networkMode = "awsvpc"

      image = var.docker_image_url

      essential = true

      portMappings = [
        {
          hostPort      = var.host_port
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      environment = [
        {
          name  = "APP_DEBUG"
          value = "false"
        },
        {
          name  = "KEYCLOAK_URL"
          value = var.keycloak_url
        },
        {
          name  = "ROOT_PATH"
          value = var.root_path
        }
      ]

      secrets = [
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.obi_generative_gui_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "obi_generative_gui"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_obi_generative_gui_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_obi_generative_gui_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.obi_generative_gui_ecs_task_logs,
  ]
}

resource "aws_ecs_service" "obi_generative_gui_ecs_service" {
  name            = "obi_generative_gui_ecs_service"
  cluster         = aws_ecs_cluster.obi_generative_gui.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.obi_generative_gui_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.obi_generative_gui_private_tg.arn
    container_name   = "obi_generative_gui"
    container_port   = var.container_port
  }

  network_configuration {
    security_groups = [aws_security_group.obi_generative_gui_ecs_task.id]
    subnets = [aws_subnet.obi_generative_gui_ecs_a.id,
      aws_subnet.obi_generative_gui_ecs_b.id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_obi_generative_gui_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "ecs_obi_generative_gui_task_execution_role" {
  name_prefix = "obi_generative_gui_ecs"

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

resource "aws_iam_role_policy_attachment" "ecs_obi_generative_gui_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_obi_generative_gui_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_obi_generative_gui_task_role" {
  name_prefix = "obi_generative_gui_ecs"

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

resource "aws_iam_policy" "ecs_task_logs_obi_generative_gui" {
  name_prefix = "obi_generative_gui_ecs"
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

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_obi_generative_gui_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs_obi_generative_gui.arn
}
