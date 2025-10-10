resource "aws_cloudwatch_log_group" "ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "notebook_service_ecs"
  skip_destroy      = false
  retention_in_days = 365

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "notebook_service"
  }
}

resource "aws_ecs_cluster" "cluster" {
  name = "notebook_service_ecs_cluster"

  tags = {
    Name = "notebook_service"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_security_group" "ecs_security_group" {
  name_prefix = "notebook_service_ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for notebook service"

  tags = {
    Name = "notebook_service_secgroup"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ecs_allow_port_8000" {
  security_group_id = aws_security_group.ecs_security_group.id
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  description       = "Allow port 8000 http"
}

# resource "aws_vpc_security_group_ingress_rule" "ecs_allow_in_tcp" {
#   security_group_id = aws_security_group.ecs_security_group.id
#   # TODO limit to what is needed
#   ip_protocol = "tcp"
#   from_port   = 0
#   to_port     = 65535
#   cidr_ipv4   = "0.0.0.0/0"
#   description = "Allow all TCP"
# }

resource "aws_vpc_security_group_egress_rule" "ecs_allow_outgoing_https" {
  security_group_id = aws_security_group.ecs_security_group.id

  ip_protocol = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all HTTPS"
}

resource "aws_vpc_security_group_egress_rule" "ecs_allow_outgoing_http" {
  security_group_id = aws_security_group.ecs_security_group.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all HTTP"
}

resource "aws_vpc_security_group_egress_rule" "ecs_allow_outgoing_dns_tcp" {
  security_group_id = aws_security_group.ecs_security_group.id

  ip_protocol = "tcp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all DNS TCP"
}

resource "aws_vpc_security_group_egress_rule" "ecs_allow_outgoing_dns_udp" {
  security_group_id = aws_security_group.ecs_security_group.id

  ip_protocol = "udp"
  from_port   = 53
  to_port     = 53
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all DNS UDP"
}

resource "aws_ecs_task_definition" "ecs_definition" {
  family       = "notebook_service_task_family"
  network_mode = "awsvpc"

  cpu    = var.task_size.cpu
  memory = var.task_size.memory

  requires_compatibilities = ["FARGATE"]

  container_definitions = jsonencode([
    {
      name   = "notebook_service"
      family = "notebook_service"

      cpu    = var.task_size.cpu
      memory = var.task_size.memory

      networkMode = "awsvpc"

      image = var.docker_image_url

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
          value = var.debug
        },
        {
          name  = "BASE_PATH"
          value = var.base_path
        },
        {
          name  = "ACCOUNTING_BASE_URL"
          value = var.accounting_base_url
        },
        {
          name  = "HUB_ON_EKS_FULL_URL",
          value = var.hub_on_eks_full_url
        },
        {
          name  = "ACCOUNTING_ENABLED",
          value = var.accounting_enabled ? "True" : "False"
        },
        {
          name  = "KUBERNETES_THREAD_ENABLED",
          value = var.kubernetes_thread_enabled ? "True" : "False"
        },
        {
          name  = "CORS_ALLOWED_ORIGINS",
          value = var.cors_allowed_origins
        },
        {
          name  = "KEYCLOAK_URL",
          value = var.keycloak_url
        },
        {
          name  = "ENVIRONMENT",
          value = var.environment
        }
      ]
      secrets = [
        {
          name      = "JUPYTERHUB_ROOT_FULL_URL"
          valueFrom = "${var.secrets_arn}:jupyterhub_root_full_url::"
        },
        {
          name      = "HUB_ON_EKS_ADMIN_TOKEN"
          valueFrom = "${var.secrets_arn}:hub_on_eks_admin_token::"
        },
        {
          name      = "EKS_CLUSTER_NAME"
          valueFrom = "${var.secrets_arn}:eks_cluster_name::"
        },
        {
          name      = "INIT_SCRIPT_GITHUB_TOKEN"
          valueFrom = "${var.secrets_arn}:init_script_github_token::"
        },
        {
          name      = "INIT_SCRIPT_GITHUB_URL"
          valueFrom = "${var.secrets_arn}:init_script_github_url::"
        }

      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "notebook_service"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.ecs_task_logs,
  ]
}

resource "aws_ecs_service" "ecs_service" {
  name            = "notebook_service_ecs_service"
  cluster         = aws_ecs_cluster.cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.ecs_definition.arn

  load_balancer {
    target_group_arn = aws_lb_target_group.private_tg.arn
    container_name   = "notebook_service"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.ecs_security_group.id]
    subnets          = [aws_subnet.ecs_a.id, aws_subnet.ecs_b.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.ecs_task_execution_role,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name_prefix = "notebook_service_task_exec_ecs"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "ecs-tasks.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix = "notebook_service_task_ecs"

  assume_role_policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Action : "sts:AssumeRole",
        Principal : {
          Service : "ecs-tasks.amazonaws.com"
        },
        Effect : "Allow",
        Sid : ""
      }
    ]
  })
}

resource "aws_iam_policy" "eks_access" {
  name_prefix = "notebook_service_ecs_eks_policy"
  description = "Policy that gives access to EKS for the notebook service"


  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.eks_access.arn
}

resource "aws_iam_policy" "ecs_task_logs" {
  name_prefix = "notebook_service_ecs"
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
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_logs.arn
}

resource "aws_iam_role_policy_attachment" "ecs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "secrets_access_policy_attachment" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.secrets_access.arn
}
