module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = var.neuroagent_bucket_name
  acl    = "private"

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  versioning = {
    enabled = false
  }
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ecs_service_agent" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                  = "ecs-service-agent"
  cluster_arn           = local.ecs_cluster_arn
  task_exec_secret_arns = [var.ml_secrets_arn, module.ml_rds_postgres.db_instance_master_user_secret_arn]


  cpu    = 1024
  memory = 2048

  # Enables ECS Exec
  enable_execute_command = true

  enable_autoscaling       = true
  autoscaling_max_capacity = 5
  autoscaling_min_capacity = 1

  # Container definition(s)
  container_definitions = {
    ml_agent = {
      memory                   = 2048
      cpu                      = 1024
      networkMode              = "awsvpc"
      family                   = "ml_agent"
      essential                = true
      image                    = "${module.ml_ecr.repository_url}:${var.agent_image_tag}"
      name                     = "ml_agent"
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
          name  = "NEUROAGENT_DB__HOST"
          value = module.ml_rds_postgres.db_instance_address
        },
        {
          name  = "NEUROAGENT_DB__NAME"
          value = var.rds_db_name
        },
        {
          name  = "NEUROAGENT_DB__PORT"
          value = module.ml_rds_postgres.db_instance_port
        },
        {
          name  = "NEUROAGENT_DB__PREFIX"
          value = "postgresql+asyncpg://"
        },
        {
          name  = "NEUROAGENT_DB__USER"
          value = module.ml_rds_postgres.db_instance_username
        },
        {
          name  = "NEUROAGENT_KEYCLOAK__ISSUER"
          value = "https://${var.primary_domain}/auth/realms/SBO"
        },
        {
          name  = "NEUROAGENT_KNOWLEDGE_GRAPH__BASE_URL"
          value = "https://${var.nexus_domain_name}/api/nexus/v1"
        },
        {
          name  = "NEUROAGENT_MISC__APPLICATION_PREFIX"
          value = "/api/agent"
        },
        {
          name  = "NEUROAGENT_MISC__CORS_ORIGINS"
          value = "https://${var.primary_domain},https://www.${var.primary_domain}"
        },
        {
          name  = "NEUROAGENT_OPENAI__MODEL"
          value = "gpt-4o-mini"
        },
        {
          name  = "NEUROAGENT_STORAGE__BUCKET_NAME"
          value = var.neuroagent_bucket_name
        },
        {
          name  = "NEUROAGENT_RATE_LIMITER__LIMIT_CHAT"
          value = "30"
        },
        {
          name  = "NEUROAGENT_RATE_LIMITER__REDIS_HOST"
          value = aws_elasticache_cluster.ml_redis_cluster.cache_nodes[0].address
        },
        {
          name  = "NEUROAGENT_RATE_LIMITER__REDIS_PORT"
          value = aws_elasticache_cluster.ml_redis_cluster.port
        },
        {
          name  = "NEUROAGENT_TOOLS__LITERATURE__RETRIEVER_K"
          value = "100"
        },
        {
          name  = "NEUROAGENT_TOOLS__LITERATURE__URL"
          value = "http://${var.private_alb_dns}:3000/api/literature/retrieval/"
        },
      ]
      secrets = [
        {
          name      = "NEUROAGENT_DB__PASSWORD"
          valueFrom = "${module.ml_rds_postgres.db_instance_master_user_secret_arn}:password::"
        },
        {
          name      = "NEUROAGENT_OPENAI__TOKEN"
          valueFrom = "${var.ml_secrets_arn}:OPENAI_API_KEY::"
        },
        {
          name      = "NEUROAGENT_TOOLS__WEB_SEARCH__TAVILY_API_KEY"
          valueFrom = "${var.ml_secrets_arn}:TAVILY_API_KEY::"
        },
      ]
      readonly_root_filesystem = false
    }
  }

  task_exec_iam_role_policies = {
    log-policy = aws_iam_policy.ml_ecs_agent_log_policy.arn
  }

  # Add the S3 policy to the task role (not execution role)
  tasks_iam_role_policies = {
    s3-policy = aws_iam_policy.ml_ecs_agent_s3_policy.arn
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
    generic_private_service = {
      target_group_arn = aws_lb_target_group.generic_private_ml_target_group_agent.arn
      container_name   = "ml_agent"
      container_port   = 8078
    }
  }

  subnet_ids = local.private_subnet_ids
  security_group_rules = {
    generic_private_alb = {
      type                     = "ingress"
      from_port                = 8078
      to_port                  = 8078
      protocol                 = "tcp"
      description              = "Service port"
      source_security_group_id = var.generic_private_alb_security_group_id
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

resource "aws_lb_listener_rule" "generic_private_agent_rule" {
  listener_arn = var.generic_private_alb_listener_arn
  priority     = 575

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.generic_private_ml_target_group_agent.arn
  }

  condition {
    path_pattern {
      values = ["/api/agent/*"]
    }
  }
}

resource "aws_lb_target_group" "generic_private_ml_target_group_agent" {
  name        = "generic-private-ml-tg-agent"
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

resource "aws_iam_policy" "ml_ecs_agent_s3_policy" {
  name = "ml_ecs_agent_s3_access"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*"
        ]
        Resource = [
          module.s3_bucket.s3_bucket_arn,
          "${module.s3_bucket.s3_bucket_arn}/*"
        ]
      }
    ]
  })
  tags = var.tags
}
