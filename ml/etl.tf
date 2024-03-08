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
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }

      port_mappings = [
        {
          name          = "ml_etl"
          containerPort = 3000
          hostPort      = 3000
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ml_etl"
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_etl"
        }
      }
    }
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
      cidr_blocks = [var.vpc_cidr_block]
    }
  }
  tags = {
    Name        = "ml_etl"
    SBO_Billing = "machinelearning"
  }
}


resource "aws_service_discovery_http_namespace" "ml_etl" {
  name        = "ml_etl"
  description = "CloudMap namespace for ml_etl"
}


resource "aws_lb_target_group" "ml_target_group_etl_private" {
  name        = "target-group-etl-private"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
}


resource "aws_lb_listener_rule" "ml_etl_rule_private" {
  listener_arn = var.private_alb_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml_target_group_etl_private.arn
  }

  condition {
    path_pattern {
      values = ["/jats_xml", "/pubmed_xml", "/tei_xml", "/xocs_xml", "/pypdf_pdf", "/core_json", "/grobid_pdf"]
    }
  }
}