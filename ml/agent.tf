#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ecs_service_agent" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                  = "ecs-service-agent"
  cluster_arn           = local.ecs_cluster_arn
  task_exec_secret_arns = [var.secret_manager_arn, var.dockerhub_credentials_arn, module.ml_rds_postgres.db_instance_master_user_secret_arn]


  cpu    = 1024
  memory = 2048

  # Enables ECS Exec
  enable_execute_command = true
  enable_autoscaling     = false

  # Container definition(s)
  container_definitions = {
    ml_agent = {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "ml_agent"
      essential   = true
      image       = var.agent_image_url
      name        = "ml_agent"
      repository_credentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      readonly_root_filesystem = false
      port_mappings = [
        {
          name          = "ml_agent"
          containerPort = 8078
          hostPort      = 8078
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "AGENT_TOOLS__LITERATURE__URL"
          value = "http://${var.private_alb_dns}:3000/api/literature/retrieval/"
        },
        {
          name  = "AGENT_KNOWLEDGE_GRAPH__BASE_URL"
          value = "https://openbluebrain.com/api/nexus/v1"
        },
        {
          name  = "AGENT_AGENT__MODEL"
          value = "simple"
        },
        {
          name  = "AGENT_GENERATIVE__LLM_TYPE"
          value = "openai"
        },
        {
          name  = "AGENT_GENERATIVE__OPENAI__MODEL"
          value = "gpt-4o-mini"
        },
        {
          name  = "AGENT_TOOLS__MORPHO__SEARCH_SIZE"
          value = "10"
        },
        {
          name  = "AGENT_TOOLS__KG_MORPHO__SEARCH_SIZE"
          value = "6"
        },
        {
          name  = "AGENT_TOOLS__TRACE__SEARCH_SIZE"
          value = "10"
        },
        {
          name  = "AGENT_TOOLS__LITERATURE__RERANKER_K"
          value = "8"
        },
        {
          name  = "AGENT_KEYCLOAK__VALIDATE_TOKEN"
          value = "true"
        },
        {
          name  = "AGENT_KEYCLOAK__ISSUER"
          value = "https://openbluebrain.com/auth/realms/SBO"
        },
        {
          name  = "AGENT_KNOWLEDGE_GRAPH__DOWNLOAD_HIERARCHY"
          value = "true"
        },
        {
          name  = "AGENT_KEYCLOAK__CLIENT_ID"
          value = "obp-ml-agent"
        },
        {
          name  = "AGENT_KEYCLOAK__USERNAME"
          value = "sbo-ml"
        },
        {
          name  = "AGENT_DB__PREFIX"
          value = "postgresql://"
        },
        {
          name  = "AGENT_DB__HOST"
          value = module.ml_rds_postgres.db_instance_address
        },
        {
          name  = "AGENT_DB__PORT"
          value = module.ml_rds_postgres.db_instance_port
        },
        {
          name  = "AGENT_DB__USER"
          value = module.ml_rds_postgres.db_instance_username
        },
        {
          name  = "AGENT_MISC__APPLICATION_PREFIX"
          value = "/api/agent"
        },
        {
          name  = "AGENT_MISC__CORS_ORIGINS"
          value = "https://openbrainplatform.org, https://bbp.epfl.ch"
        },
      ]
      secrets = [
        {
          name      = "AGENT_GENERATIVE__OPENAI__TOKEN"
          valueFrom = "${var.secret_manager_arn}:OPENAI_API_KEY::"
        },
        {
          name      = "AGENT_COHERE__TOKEN"
          valueFrom = "${var.secret_manager_arn}:COHERE_TOKEN::"
        },
        {
          name      = "AGENT_DB__PASSWORD"
          valueFrom = "${module.ml_rds_postgres.db_instance_master_user_secret_arn}:password::"
        },
        {
          name      = "AGENT_KEYCLOAK__PASSWORD"
          valueFrom = "${var.secret_manager_arn}:KEYCLOAK_PASSWORD::"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "ml_agent"
          awslogs-region        = "us-east-1"
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_agent"
        }
      }
      readonly_root_filesystem = false
    }
    tags = var.tags
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_agent_log_policy.arn
  }

  service_connect_configuration = {
    namespace = aws_service_discovery_http_namespace.ml_agent.arn
    service = {
      client_alias = {
        port     = 8078
        dns_name = "ml_agent"
      }
      port_name      = "ml_agent"
      discovery_name = "ml_agent"
    }
  }

  load_balancer = {
    service = {
      target_group_arn = aws_lb_target_group.ml_target_group_agent.arn
      container_name   = "ml_agent"
      container_port   = 8078
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    alb_ingress_3000 = {
      type                     = "ingress"
      from_port                = 8078
      to_port                  = 8078
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = var.alb_security_group_id
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

resource "aws_service_discovery_http_namespace" "ml_agent" {
  name        = "ml_agent"
  description = "CloudMap namespace for ml_agent"

  tags = var.tags
}

resource "aws_lb_listener_rule" "agent_rule" {
  listener_arn = var.alb_listener_arn
  priority     = 575

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ml_target_group_agent.arn
  }

  condition {
    path_pattern {
      values = ["/api/agent/*"]
    }
  }

  condition {
    source_ip {
      values = ["128.178.0.0/15", "192.33.211.0/26"] # EPFL CIDR, BBP DMZ CIDR
    }
  }
}

resource "aws_lb_target_group" "ml_target_group_agent" {
  name        = "ml-target-group-agent"
  port        = 8078
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/healthz"
  }
}

resource "aws_iam_policy" "ml_ecs_agent_log_policy" {
  name = "ml_ecs_agent_logs"
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
