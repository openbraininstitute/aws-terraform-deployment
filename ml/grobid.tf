#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ml-ecs_service_grobid" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name        = "ml-ecs-service-grobid"
  cluster_arn = local.ecs_cluster_arn

  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = true
  enable_autoscaling     = false

  # Container definition(s)
  container_definitions = {
    ml_grobid = {
      cpu                      = 1024
      memory                   = 4096
      networkMode              = "awsvpc"
      family                   = "ml_grobid"
      essential                = true
      image                    = var.grobid_image_url
      name                     = "ml_grobid"
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "ml_grobid"
          containerPort = 8070
          hostPort      = 8070
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ml_grobid"
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_grobid"
        }
      }
    }
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_etl_log_policy.arn
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.ml_grobid.arn
    service = {
      client_alias = {
        port     = 8070
        dns_name = "ml_grobid"
      }
      port_name      = "ml_grobid"
      discovery_name = "ml_grobid"
    }
  }

  load_balancer = {
    service_private = {
      target_group_arn = aws_lb_target_group.target_group_grobid_private.arn
      container_name   = "ml_grobid"
      container_port   = 8070
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    private_alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 8070
      to_port                  = 8070
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
  tags = {
    Name        = "ml_grobid"
    SBO_Billing = "machinelearning"
  }
}


resource "aws_service_discovery_http_namespace" "ml_grobid" {
  name        = "ml_grobid"
  description = "CloudMap namespace for ml_grobid"
}

resource "aws_lb_target_group" "target_group_grobid_private" {
  name        = "target-group-grobid-private"
  port        = 8070
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}


resource "aws_lb_listener_rule" "grobid_rule_private" {
  listener_arn = var.private_alb_listener_arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group_grobid_private.arn
  }

  condition {
    path_pattern {
      values = ["/api/*"]
    }
  }
}

resource "aws_iam_policy" "ml_ecs_grobid_log_policy" {
  name = "ml_ecs_grobid_logs"
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
}