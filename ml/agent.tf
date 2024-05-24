#tfsec:ignore:aws-ec2-no-public-egress-sgr
module "ecs_service_agent" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  name                  = "ecs-service-agent"
  cluster_arn           = local.ecs_cluster_arn
  task_exec_secret_arns = [var.secret_manager_arn, var.dockerhub_credentials_arn]


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
          name  = "AGENT_TOOLS__KNOWLEDGE_GRAPH__URL"
          value = "https://bbp.epfl.ch/nexus/v1/search/query/suite/sbo"
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
          value = "gpt-3.5-turbo"
        },
        {
          name  = "AGENT_TOOLS__KNOWLEDGE_GRAPH__SEARCH_SIZE"
          value = "3"
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
          name      = "AGENT_TOOLS__KNOWLEDGE_GRAPH__TOKEN"
          valueFrom = "${var.secret_manager_arn}:KG_TOKEN::"
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
  tags = var.tags
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
      values = ["128.178.0.0/15"]
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