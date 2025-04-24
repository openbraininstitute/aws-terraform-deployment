locals {
  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "obi_one_ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "obi_one_ecs"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "obi_one"
  }
}

resource "aws_ecs_cluster" "obi_one" {
  name = "obi_one_ecs_cluster"

  tags = {
    Name = "obi_one"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_security_group" "obi_one_ecs_task" {
  name_prefix = "obi_one_ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for obi-one service"

  tags = {
    Name = "obi_one_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "obi_one_allow_container_port" {
  security_group_id = aws_security_group.obi_one_ecs_task.id

  ip_protocol = "tcp"
  from_port   = var.container_port
  to_port     = var.container_port
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow access to the container port"
}


resource "aws_vpc_security_group_egress_rule" "obi_one_allow_outgoing" {
  security_group_id = aws_security_group.obi_one_ecs_task.id
  description       = "Allow egress to any destination"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    SBO_Billing = "obi_one"
    Name        = "obi_one_allow_outgoing"
  }
}

resource "aws_ecs_task_definition" "obi_one_ecs_definition" {
  family       = "obi_one_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "obi_one"
      family = "obi_one"

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
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
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
          awslogs-group         = aws_cloudwatch_log_group.obi_one_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "obi_one"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_obi_one_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_obi_one_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.obi_one_ecs_task_logs,
  ]
}

resource "aws_ecs_service" "obi_one_ecs_service" {
  name            = "obi_one_ecs_service"
  cluster         = aws_ecs_cluster.obi_one.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.obi_one_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.obi_one_private_tg.arn
    container_name   = "obi_one"
    container_port   = var.container_port
  }

  network_configuration {
    security_groups = [aws_security_group.obi_one_ecs_task.id]
    subnets = [aws_subnet.obi_one_ecs_a.id,
      aws_subnet.obi_one_ecs_b.id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_obi_one_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "ecs_obi_one_task_execution_role" {
  name_prefix = "obi_one_ecs"

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

resource "aws_iam_role_policy_attachment" "ecs_obi_one_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_obi_one_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_obi_one_task_role" {
  name_prefix = "obi_one_ecs"

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

resource "aws_iam_policy" "ecs_task_logs_obi_one" {
  name_prefix = "obi_one_ecs"
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
  role       = aws_iam_role.ecs_obi_one_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs_obi_one.arn
}
