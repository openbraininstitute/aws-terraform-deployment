locals {
  cpu    = 256
  memory = 512
}

resource "aws_cloudwatch_log_group" "accounting_ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "acc_ecs"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "accounting"
  }
}

resource "aws_ecs_cluster" "accounting" {
  name = "accounting_ecs_cluster"

  tags = {
    Name = "accounting"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "accounting_ecs_task" {
  name_prefix = "ac_ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for accounting service"

  tags = {
    Name = "accounting_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "accounting_allow_port_8000" {
  security_group_id = aws_security_group.accounting_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.aws_vpc.main.cidr_block
  description = "Allow port 8000 http"
}

resource "aws_vpc_security_group_ingress_rule" "accounting_allow_in_tcp" {
  security_group_id = aws_security_group.accounting_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "accounting_allow_outgoing_tcp" {
  security_group_id = aws_security_group.accounting_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "accounting_allow_outgoing_udp" {
  security_group_id = aws_security_group.accounting_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "accounting_ecs_definition" {
  family       = "accounting_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "accounting"
      family = "accounting"

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
          value = "false"
        },
        {
          name  = "ROOT_PATH"
          value = var.root_path
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.accounting.address
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
          name  = "SQS_STORAGE_QUEUE_NAME"
          value = module.storage_event_queue_set.main_queue_name
        },
        {
          name  = "SQS_LONGRUN_QUEUE_NAME"
          value = module.longrun_event_queue_set.main_queue_name
        },
        {
          name  = "SQS_ONESHOT_QUEUE_NAME"
          value = module.oneshot_event_queue_set.main_queue_name
        }
      ]

      secrets = [
        {
          name      = "DB_PASS"
          valueFrom = var.accounting_service_secrets_arn
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.accounting_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "accounting"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_accounting_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_accounting_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.accounting_ecs_task_logs,
  ]
}

resource "aws_ecs_service" "accounting_ecs_service" {
  name            = "accounting_ecs_service"
  cluster         = aws_ecs_cluster.accounting.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.accounting_ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.accounting_private_tg.arn
    container_name   = "accounting"
    container_port   = 8000
  }

  network_configuration {
    security_groups = [aws_security_group.accounting_ecs_task.id]
    subnets = [aws_subnet.accounting_ecs_a.id,
      aws_subnet.accounting_ecs_b.id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_accounting_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "ecs_accounting_task_execution_role" {
  name_prefix = "acc_ecs"

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

resource "aws_iam_role_policy_attachment" "ecs_accounting_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_accounting_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "ecs_accounting_task_role" {
  name_prefix = "acc_ecs"

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

resource "aws_iam_policy" "ecs_task_logs_accounting" {
  name_prefix = "acc_ecs"
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
  role       = aws_iam_role.ecs_accounting_task_execution_role.name
  policy_arn = var.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "secrets" {
  role       = aws_iam_role.ecs_accounting_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "execution_logs" {
  role       = aws_iam_role.ecs_accounting_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs_accounting.arn
}

resource "aws_iam_policy" "read_queues" {
  name_prefix = "acc_q"
  description = "Allow read of SQS accounting queues"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action : [
          "sqs:GetQueueUrl",
          "sqs:ListDeadLetterSourceQueues",
          "sqs:ListMessageMoveTasks",
          "sqs:ReceiveMessage",
          "sqs:GetQueueAttributes",
          "sqs:ListQueueTags"
        ],
        "Resource" : [
          module.storage_event_queue_set.main_queue_arn,
          module.longrun_event_queue_set.main_queue_arn,
          module.oneshot_event_queue_set.main_queue_arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "send_message" {
  role       = aws_iam_role.ecs_accounting_task_role.name
  policy_arn = aws_iam_policy.read_queues.arn
}
