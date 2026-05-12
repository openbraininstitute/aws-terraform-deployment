module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "v4.11.0"

  bucket                                = var.neuroagent_bucket_name
  acl                                   = "private"
  attach_deny_insecure_transport_policy = true

  control_object_ownership = true
  object_ownership         = "ObjectWriter"

  cors_rule = [
    {
      allowed_methods = ["GET"]
      allowed_origins = var.cors_origins
      allowed_headers = ["x-amz-meta-category"]
      expose_headers  = ["x-amz-meta-category"]
    }
  ]

  versioning = {
    enabled = false
  }

  tags = var.is_production ? { obi_backup_plan = var.obi_backup_plan } : {}
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ecs_service_agent" {
  source  = "terraform-aws-modules/ecs/aws//modules/service"
  version = "v5.12.1"

  name                  = local.ecs_service_name
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
    (local.agent_container_name) = {
      memory                   = 2048
      cpu                      = 1024
      networkMode              = "awsvpc"
      essential                = true
      image                    = var.neuroagent_docker_image_url
      name                     = local.agent_container_name
      readonly_root_filesystem = true
      mount_points = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
        }
      ]
      port_mappings = [
        {
          name          = local.service_connect_port_name
          containerPort = 8078
          hostPort      = 8078
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "NEUROAGENT__ACCOUNTING__BASE_URL"
          value = "https://${var.primary_domain}/api/accounting"
        },
        {
          name  = "NEUROAGENT__DB__HOST"
          value = module.ml_rds_postgres.db_instance_address
        },
        {
          name  = "NEUROAGENT__DB__NAME"
          value = var.rds_db_name
        },
        {
          name  = "NEUROAGENT__DB__PORT"
          value = module.ml_rds_postgres.db_instance_port
        },
        {
          name  = "NEUROAGENT__DB__PREFIX"
          value = "postgresql+asyncpg://"
        },
        {
          name  = "NEUROAGENT__DB__USER"
          value = module.ml_rds_postgres.db_instance_username
        },
        {
          name  = "NEUROAGENT__KEYCLOAK__ISSUER"
          value = var.keycloak_sbo_realm_url
        },
        {
          name  = "NEUROAGENT__LLM__WHITELISTED_MODEL_IDS_REGEX"
          value = "openai/gpt-5.*"
        },
        {
          name  = "NEUROAGENT__MISC__APPLICATION_PREFIX"
          value = var.neuroagent_application_prefix
        },
        {
          name  = "NEUROAGENT__MISC__CORS_ORIGINS"
          value = join(",", var.cors_origins)
        },
        {
          name  = "NEUROAGENT__STORAGE__BUCKET_NAME"
          value = var.neuroagent_bucket_name
        },
        {
          name  = "NEUROAGENT__RATE_LIMITER__LIMIT_CHAT"
          value = "30"
        },
        {
          name  = "NEUROAGENT__RATE_LIMITER__REDIS_HOST"
          value = aws_elasticache_cluster.ml_redis_cluster.cache_nodes[0].address
        },
        {
          name  = "NEUROAGENT__RATE_LIMITER__REDIS_PORT"
          value = aws_elasticache_cluster.ml_redis_cluster.port
        },
        {
          name  = "NEUROAGENT__TOOLS__OBI_ONE__URL"
          value = "https://${var.primary_domain}/api/obi-one"
        },
        {
          name  = "NEUROAGENT__TOOLS__ENTITYCORE__URL"
          value = "https://${var.primary_domain}/api/entitycore"
        },
        {
          name  = "NEUROAGENT__TOOLS__THUMBNAIL_GENERATION__URL"
          value = "https://${var.primary_domain}/api/thumbnail-generation"
        },
        {
          name  = "NEUROAGENT__TOOlS__FRONTEND_BASE_URL"
          value = "https://${var.frontend_domain}"
        },
        {
          name  = "NEUROAGENT__TOOLS__WHITELISTED_TOOL_REGEX"
          value = "^(?!.*(downloadone|measurementannotation|experimentalsynapsesperconnection|weather)).*"
        },
      ]
      secrets = [
        {
          name      = "NEUROAGENT__DB__PASSWORD"
          valueFrom = "${module.ml_rds_postgres.db_instance_master_user_secret_arn}:password::"
        },
        {
          name      = "NEUROAGENT__LLM__OPENAI_TOKEN"
          valueFrom = "${var.ml_secrets_arn}:OPENAI_API_KEY::"
        },
        {
          name      = "NEUROAGENT__LLM__OPEN_ROUTER_TOKEN"
          valueFrom = "${var.ml_secrets_arn}:OPENROUTER_API_KEY::"
        },
        {
          name      = "NEUROAGENT__TOOLS__EXA_API_KEY"
          valueFrom = "${var.ml_secrets_arn}:EXA_API_KEY::"
        },
      ]
    }
  }

  volume = {
    tmp = {}
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
        dns_name = local.service_connect_port_name
      }
      port_name      = local.service_connect_port_name
      discovery_name = local.service_connect_port_name
    }
  }

  load_balancer = {
    generic_private_service = {
      target_group_arn = aws_lb_target_group.generic_private_ml_target_group_agent.arn
      container_name   = local.agent_container_name
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
  name        = local.service_discovery_namespace_name
  description = local.legacy ? "CloudMap namespace for ml_agent" : "CloudMap namespace for neuroagent (${local.ml_prefix})"

  tags = var.tags
}

resource "aws_lb_listener_rule" "generic_private_agent_rule" {
  listener_arn = var.generic_private_alb_listener_arn
  priority     = var.agent_alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.generic_private_ml_target_group_agent.arn
  }

  condition {
    path_pattern {
      values = var.agent_path_pattern
    }
  }
}

resource "aws_lb_target_group" "generic_private_ml_target_group_agent" {
  name        = local.agent_target_group_name
  port        = 8078
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path = "/healthz"
  }
}

resource "aws_iam_policy" "ml_ecs_agent_log_policy" {
  name = local.iam_log_policy_name
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
  name = local.iam_s3_policy_name
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
