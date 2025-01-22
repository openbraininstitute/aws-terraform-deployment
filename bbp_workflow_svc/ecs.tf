locals {
  cluster_name = replace(var.svc_name, "-", "_")
}

# data "aws_subnet" "ecs" {
#   id = var.ecs_subnet_id
# }

resource "aws_vpc_security_group_ingress_rule" "this" {
  security_group_id            = var.ecs_secgrp_id
  referenced_security_group_id = var.ecs_secgrp_id
  # from_port                    = 443
  # to_port                      = 443
  ip_protocol = "-1"
}

# resource "aws_vpc_security_group_ingress_rule" "in_TLS" {
#   security_group_id            = aws_security_group.ecs.id
#   referenced_security_group_id = "sg-06915253e03bb4cd2"
#   from_port                    = 443
#   to_port                      = 443
#   ip_protocol                  = "tcp"
# }

# resource "aws_vpc_security_group_ingress_rule" "in_8100_for_svc" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = data.aws_subnet.ecs.cidr_block
#   ip_protocol       = "tcp"
#   from_port         = 8100
#   to_port           = 8100
# }
#
# resource "aws_vpc_security_group_ingress_rule" "in_8101_for_svc_sc" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = data.aws_subnet.ecs.cidr_block
#   ip_protocol       = "tcp"
#   from_port         = 8101
#   to_port           = 8101
# }

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = var.ecs_secgrp_id
  cidr_ipv4         = "0.0.0.0/0"
  # from_port         = 443
  # to_port           = 443
  ip_protocol = "-1"
}

# resource "aws_vpc_security_group_egress_rule" "out_tls" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   to_port           = 443
#   ip_protocol       = "tcp"
# }

# resource "aws_vpc_security_group_egress_rule" "out_dns_tcp" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 53
#   to_port           = 53
#   ip_protocol       = "tcp"
# }
#
# resource "aws_vpc_security_group_egress_rule" "out_dns_udp" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 53
#   to_port           = 53
#   ip_protocol       = "udp"
# }

# resource "aws_vpc_security_group_egress_rule" "out_8080_for_lambda" {
#   security_group_id = aws_security_group.ecs.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 8080
#   to_port           = 8080
#   ip_protocol       = "tcp"
# }

resource "aws_ecs_cluster" "this" {
  name = local.cluster_name
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
  tags       = var.tags
  depends_on = [aws_cloudwatch_log_group.ecs]
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${local.cluster_name}"
  retention_in_days = 3
  tags              = var.tags
}

data "aws_iam_policy_document" "task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "task" {
  name               = "${var.svc_name}-ecs-task"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  # inline_policy {
  #   name = "${var.svc_name}-ecs-task-logs"
  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [{
  #       Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
  #       Effect   = "Allow"
  #       Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
  #     }]
  #   })
  # }
  inline_policy {
    name = "${var.svc_name}-ecs-ssm"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ]
        Effect   = "Allow"
        Resource = "*"
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-api-gateway-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          "execute-api:Invoke"
        ]
        Effect = "Allow"
        Resource = "*"
      }]
    })
  }
}

resource "aws_iam_role" "task_exec" {
  name               = "${var.svc_name}-ecs-task-exec"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role.json
  # inline_policy {
  #   name = "${var.svc_name}-ecs-task-logs"
  #   policy = jsonencode({
  #     Version = "2012-10-17"
  #     Statement = [{
  #       Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
  #       Effect   = "Allow"
  #       Resource = "${aws_cloudwatch_log_group.ecs.arn}:*"
  #     }]
  #   })
  # }
  inline_policy {
    name = "${var.svc_name}-ecs-kc-scr-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action = [
          # "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ]
        Effect = "Allow"
        # Resource = [var.kc_scr, var.id_rsa_scr]
        Resource = [var.kc_scr]
      }]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy",
  ]
}

resource "aws_ecs_task_definition" "this" {
  family                   = local.cluster_name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  memory                   = 512
  cpu                      = 256
  container_definitions = jsonencode([
    {
      name        = local.cluster_name
      networkMode = "awsvpc"
      # family      = local.cluster_name
      essential = true
      image     = var.svc_image
      linuxParameters = {
        initProcessEnabled = true
      }
      environment : [
        { name : "USER", value : "bbp-workflow" },
        { name : "REDIRECT_URI", value : "https://${data.aws_apigatewayv2_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/auth/?url=%s" },
        { name : "KC_HOST", value : "https://{var.primary_domain}" },
        { name : "KC_REALM", value : "SBO" },
        { name : "KC_CLIENT_ID", value : "bbp-workflow" },
        { name : "WORKFLOWS_PATH", value : "/home/bbp-workflow/workflows" },
        { name : "HPC_ENVIRONMENT", value : "aws" },
        { name : "HPC_HEAD_NODE", value : var.hpc_head_node },
        { name : "HPC_PATH_PREFIX", value : "/sbo/data/scratch" },
        { name : "HPC_DATA_PREFIX", value : "/sbo/data/project" },
        { name : "HPC_SIF_PREFIX", value : "/sbo/data/containers" },
        { name : "HPC_RESOURCE_PROVISIONER_API_URL", value: var.hpc_provisioner_url },
        { name : "NEXUS_BASE", value : "https://${var.nexus_domain_name}/api/nexus/v1" },
      ],
      secrets = [
        { name = "KC_SCR", valueFrom = var.kc_scr },
        # { name = "SSH_PRIVATE_KEY", valueFrom = var.id_rsa_scr },
      ]
      portMappings = [
        {
          hostPort      = 8100
          containerPort = 8100
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "curl -f -s localhost:8100/healthz/ || exit 1"]
        interval    = 8
        timeout     = 4
        startPeriod = 8
        retries     = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    },
    # {
    #   name        = local.sidecar_name
    #   networkMode = "awsvpc"
    #   essential   = true
    #   image       = "${var.svc_image}-sc:latest"
    #   linuxParameters = {
    #     initProcessEnabled = true
    #   }
    #   environment : [
    #     { name : "REDIRECT_URI", value : "https://${data.aws_apigatewayv2_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/auth/?url=%s" },
    #     { name : "KC_HOST", value : "https://{var.primary_domain}" },
    #     { name : "KC_REALM", value : "SBO" },
    #     { name : "KC_CLIENT_ID", value : "bbp-workflow" },
    #   ],
    #   secrets = [{ name = "KC_SCR", valueFrom = "${var.kc_scr}" }]
    #   # portMappings = [
    #   #   {
    #   #     hostPort      = 8101
    #   #     containerPort = 8101
    #   #     protocol      = "tcp"
    #   #   }
    #   # ]
    #   healthcheck = {
    #     command     = ["CMD-SHELL", "exit 0"]
    #     interval    = 30
    #     timeout     = 5
    #     startPeriod = 60
    #     retries     = 3
    #   }
    #   logConfiguration = {
    #     logDriver = "awslogs"
    #     options = {
    #       awslogs-group         = aws_cloudwatch_log_group.ecs.name
    #       awslogs-region        = var.aws_region
    #       awslogs-stream-prefix = "ecs"
    #     }
    #   }
    # }
  ])
  task_role_arn      = aws_iam_role.task.arn
  execution_role_arn = aws_iam_role.task_exec.arn
  tags               = var.tags
}
