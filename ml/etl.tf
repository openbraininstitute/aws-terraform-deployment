#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ml_ecs_service_etl" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "ml-ecs-service-etl"
  cluster_arn = local.ecs_cluster_arn

  cpu    = 1024
  memory = 2048

  # Enables ECS Exec
  enable_execute_command = true
  enable_autoscaling     = false

  # Container definition(s)
  container_definitions = {
    ml_etl = {
      memory                   = 2048
      cpu                      = 1024
      networkMode              = "awsvpc"
      family                   = "ml_etl"
      essential                = true
      image                    = var.etl_image_url
      name                     = "ml_etl"
      readonly_root_filesystem = false
      entrypoint               = ["scholaretl-api", "--port", "3000"]

      port_mappings = [
        {
          name          = "ml_etl"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "GROBID_URL"
          value = "http://${var.private_alb_dns}:3000"
        }
      ]
    }
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_etl_log_policy.arn
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.ml_etl.arn
    service = {
      client_alias = {
        port     = 3000
        dns_name = "ml_etl"
      }
      port_name      = "ml_etl"
      discovery_name = "ml_etl"
    }
  }

  load_balancer = {
    service_private = {
      target_group_arn = aws_lb_target_group.ml_target_group_etl_private.arn
      container_name   = "ml_etl"
      container_port   = 3000
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    private_alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 3000
      to_port                  = 3000
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = var.private_alb_security_group_id
    }
    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  tags           = var.tags
  propagate_tags = "SERVICE"
}


resource "aws_service_discovery_http_namespace" "ml_etl" {
  name        = "ml_etl"
  description = "CloudMap namespace for ml_etl"
  tags        = var.tags
}


resource "aws_lb_target_group" "ml_target_group_etl_private" {
  name        = "target-group-etl-private"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags        = var.tags
  health_check {
    path = "/healthz"
  }
}


resource "aws_lb_listener_rule" "ml_etl_rule_private" {
  listener_arn = var.private_alb_listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml_target_group_etl_private.arn
  }

  condition {
    path_pattern {
      values = var.sqs_etl_parser_list
    }
  }
  tags = var.tags
}

resource "aws_iam_policy" "ml_ecs_etl_log_policy" {
  name = "ml_ecs_etl_logs"
  policy = jsonencode({ # tfsec:ignore:aws-iam-no-policy-wildcards
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutSubscriptionFilter",
          "logs:PutLogEvents"
        ],
        "Resource" : ["*"]
      }
    ]
    }
  )
  tags = var.tags
}
