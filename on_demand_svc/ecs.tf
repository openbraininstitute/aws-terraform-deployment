locals {
  cluster_name = replace(var.svc_name, "-", "_")
}

resource "aws_security_group" "ecs" {
  name        = "${var.svc_name}-ecs-sg"
  vpc_id      = var.vpc_id
  description = "Allow 8080 inbound traffic and TLS/8080 outbound traffic"
  tags        = var.tags
}

data "aws_subnet" "ecs" {
  id = var.ecs_subnet_id
}

resource "aws_vpc_security_group_ingress_rule" "in_8080_for_svc" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = data.aws_subnet.ecs.cidr_block
  ip_protocol       = "tcp"
  from_port         = 8080
  to_port           = 8080
}

resource "aws_vpc_security_group_egress_rule" "out_tls" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "out_8080_for_lambda" {
  security_group_id = aws_security_group.ecs.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8080
  to_port           = 8080
  ip_protocol       = "tcp"
}

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags       = var.tags
  depends_on = [aws_cloudwatch_log_group.ecs]
}

resource "aws_ecs_capacity_provider" "this" {
  name = var.svc_name
  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.this.arn
    managed_scaling {
      status                 = "ENABLED"
      target_capacity        = 100
      instance_warmup_period = 10
    }
  }
  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = local.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.this.name]
  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.this.name
    base              = 0
    weight            = 1
  }
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.cluster_name}"
  retention_in_days = 3
  tags              = var.tags
}

data "aws_iam_policy_document" "task" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "post_to_connection" {
  statement {
    actions = ["execute-api:ManageConnections"]
    effect  = "Allow"
    resources = [
      "${aws_apigatewayv2_api.this.execution_arn}/prod/POST/@connections/*",
      "${aws_apigatewayv2_api.this.execution_arn}/prod/DELETE/@connections/*"
    ]
  }
}

resource "aws_iam_policy" "post_to_connection" {
  name   = "${var.svc_name}-apigw-post-to-connection"
  policy = data.aws_iam_policy_document.post_to_connection.json
  tags   = var.tags
}

resource "aws_iam_role" "task" {
  name               = "${var.svc_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess", # FIXME when vlab/project is clear
    aws_iam_policy.post_to_connection.arn,
  ]
}

data "aws_iam_policy_document" "dockerhub" {
  statement {
    actions = [
      "ssm:GetParameters",
      "secretsmanager:GetSecretValue"
    ]
    effect    = "Allow"
    resources = [var.dockerhub_creds_arn]
  }
}

resource "aws_iam_policy" "dockerhub" {
  name   = "${var.svc_name}-ecs-dockerhub-access"
  policy = data.aws_iam_policy_document.dockerhub.json
  tags   = var.tags
}

resource "aws_iam_role" "task_exec" {
  name               = "${var.svc_name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.task.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
    aws_iam_policy.dockerhub.arn,
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.cluster_name
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      name        = local.cluster_name
      memory      = var.ecs_memory
      cpu         = var.ecs_cpu
      networkMode = "awsvpc"
      family      = local.cluster_name
      essential   = true
      image       = var.svc_image
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_creds_arn
      }
      linuxParameters = {
        devices = [{
          hostPath      = "/dev/fuse"
          containerPath = "/dev/fuse"
        }]
        capabilities = {
          add  = ["SYS_ADMIN"]
          drop = []
        }
      }
      portMappings = [
        {
          hostPort      = 8080
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"]
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.task_exec.arn
  tags               = var.tags
}
