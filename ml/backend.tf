#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ml_ecs_service_backend" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                  = "ml-ecs-service-backend"
  cluster_arn           = local.ecs_cluster_arn
  task_exec_secret_arns = [var.secret_manager_arn, var.dockerhub_credentials_arn]


  cpu    = 1024
  memory = 4096

  # Enables ECS Exec
  enable_execute_command = true
  enable_autoscaling     = false

  # Container definition(s)
  container_definitions = {
    ml_backend = {
      cpu         = 1024
      memory      = 4096
      networkMode = "awsvpc"
      family      = "ml_backend"
      essential   = true
      image       = var.backend_image_url
      name        = "ml_backend"
      repository_credentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "ml_backend"
          containerPort = 8080
          hostPort      = 8080
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "SCHOLARAG__DB__DB_TYPE"
          value = "opensearch"
        },
        {
          name  = "SCHOLARAG__DB__INDEX_PARAGRAPHS"
          value = "pmc_paragraphs_v2"
        },
        {
          name  = "SCHOLARAG__DB__HOST"
          value = aws_opensearch_domain.ml_opensearch.endpoint
        },
        {
          name  = "SCHOLARAG__DB__PORT"
          value = "443"
        },
        {
          name  = "SCHOLARAG__DB__INDEX_JOURNALS"
          value = "impact_factors"
        },
        {
          name  = "SCHOLARAG__RETRIEVAL__SEARCH_TYPE"
          value = "bm25"
        },
        {
          name  = "SCHOLARAG__GENERATIVE__LLM_TYPE"
          value = "openai"
        },
        {
          name  = "SCHOLARAG__RERANKING__RERANK_TYPE"
          value = "cohere"
        },
        {
          name  = "SCHOLARAG__GENERATIVE__OPENAI__MODEL"
          value = "gpt-4o-mini"
        },
        {
          name  = "SCHOLARAG__GENERATIVE__OPENAI__TEMPERATURE"
          value = "0"
        },
        {
          name  = "SENTRY_ENVIRONMENT"
          value = "AWS_prod"
        },
        {
          name  = "SCHOLARAG__REDIS__HOST"
          value = aws_elasticache_cluster.ml_redis_cluster.cache_nodes[0].address
        },
        {
          name  = "SCHOLARAG__REDIS__PORT"
          value = aws_elasticache_cluster.ml_redis_cluster.port
        },
        {
          name  = "SCHOLARAG__KEYCLOAK__ISSUER"
          value = "https://openbluebrain.com/auth/realms/SBO"
        },
        {
          name  = "SCHOLARAG__KEYCLOAK__VALIDATE_TOKEN"
          value = "true"
        },
        {
          name  = "SCHOLARAG__MISC__APPLICATION_PREFIX"
          value = "/api/literature"
        },
        {
          name  = "SCHOLARAG__MISC__CORS_ORIGINS"
          value = "https://openbrainplatform.org, https://bbp.epfl.ch"
        },
      ]
      secrets = [
        {
          name      = "SCHOLARAG__GENERATIVE__OPENAI__TOKEN"
          valueFrom = "${var.secret_manager_arn}:OPENAI_API_KEY::"
        },
        {
          name      = "SCHOLARAG__RERANKING__COHERE__TOKEN"
          valueFrom = "${var.secret_manager_arn}:COHERE_TOKEN::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.secret_manager_arn}:SENTRY_DSN::"
        },
      ]
      log_configuration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ml_backend"
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_backend"
        }
      }
    }
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_backend_log_policy.arn
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.ml_backend_namespace.arn
    service = {
      client_alias = {
        port     = 8080
        dns_name = "ml_backend"
      }
      port_name      = "ml_backend"
      discovery_name = "ml_backend"
    }
  }

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.ml_target_group_backend.arn
      container_name   = "ml_backend"
      container_port   = 8080
    }
    private_service = {
      target_group_arn = aws_lb_target_group.ml_target_group_backend_private.arn
      container_name   = "ml_backend"
      container_port   = 8080
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = var.alb_security_group_id
    }
    private_alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 8080
      to_port                  = 8080
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

resource "aws_service_discovery_http_namespace" "ml_backend_namespace" {
  name        = "ml_backend"
  description = "CloudMap namespace for ml_backend"
  tags        = var.tags
}

resource "aws_lb_target_group" "ml_target_group_backend" {
  name        = "target-group-ml-backend"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags        = var.tags
  health_check {
    path = "/healthz"
  }
}

resource "aws_lb_target_group" "ml_target_group_backend_private" {
  name        = "target-group-backend-private"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags        = var.tags
  health_check {
    path = "/healthz"
  }
}

resource "aws_lb_listener_rule" "ml_backend_listener_rule" {
  listener_arn = var.alb_listener_arn
  priority     = 550

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml_target_group_backend.arn
  }

  condition {
    path_pattern {
      values = ["/api/literature/*"]
    }
  }

  condition {
    source_ip {
      values = ["128.178.0.0/15", "192.33.211.0/26"] # EPFL CIDR, BBP DMZ CIDR
    }
  }
  tags = var.tags
}

resource "aws_lb_listener_rule" "ml_backend_listener_rule_private" {
  listener_arn = var.private_alb_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml_target_group_backend_private.arn
  }

  condition {
    path_pattern {
      values = ["/api/literature/*"]
    }
  }
  tags = var.tags
}

resource "aws_iam_policy" "ml_ecs_backend_log_policy" {
  name = "ml_ecs_backend_logs"
  policy = jsonencode({
    "Version" : "2012-10-17", #tfsec:ignore:aws-iam-no-policy-wildcards
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
