locals {
  cpu    = 1024
  memory = 2048
}

resource "aws_cloudwatch_log_group" "core_webapp" {
  # TODO check if the logs can be encrypted
  name              = var.log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "core_webapp"
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_ecs_cluster" "core_webapp" {
  name = "core_webapp_${var.key}_ecs_cluster"

  tags = {
    Application = "core_webapp"
    SBO_Billing = var.sbo_billing_tag
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "core_webapp_ecs_task" {
  name        = "core_webapp_${var.key}_ecs_task"
  vpc_id      = var.vpc_id
  description = "Sec group for SBO core webapp"

  tags = {
    Name        = "core_webapp_secgroup"
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_vpc_security_group_ingress_rule" "core_webapp_allow_port_8000" {
  security_group_id = aws_security_group.core_webapp_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = var.vpc_cidr_block
  description = "Allow port 8000 http"
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_vpc_security_group_egress_rule" "core_webapp_allow_outgoing_tcp" {
  security_group_id = aws_security_group.core_webapp_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all TCP"
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_vpc_security_group_egress_rule" "core_webapp_allow_outgoing_udp" {
  security_group_id = aws_security_group.core_webapp_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all UDP"
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_ecs_task_definition" "core_webapp_ecs_definition" {
  count = var.ecs_number_of_containers > 0 ? 1 : 0

  family       = "core_webapp_${var.key}_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      cpu         = local.cpu
      memory      = local.memory
      networkMode = "awsvpc"
      essential   = true
      image       = var.docker_image_url
      name        = "core_webapp"

      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      environment = [
        {
          name  = "DEPLOYMENT_ENV"
          value = var.deployment_env
        },
        {
          name  = "API_ORIGIN"
          value = var.api_origin
        },
        {
          name  = "KEYCLOAK_ISSUER"
          value = var.keycloak_issuer
        },
        {
          name  = "KEYCLOAK_CLIENT_ID"
          value = "core-webapp-${var.key}"
        },
        {
          name  = "MATOMO_SITE_ID"
          value = var.matomo_site_id
        },
        {
          name  = "NEXTAUTH_URL"
          value = var.auth_url
        },
        {
          name  = "PRIMARY_HOSTNAME"
          value = var.primary_hostname
        },
        {
          name  = "SANITY_DATASET"
          value = var.sanity_dataset
        },
        {
          name  = "STRIPE_PUBLISHABLE_KEY"
          value = var.stripe_publishable_key
        },
        {
          name  = "CDN_URL"
          value = var.key == "main" ? "https://${aws_cloudfront_distribution.core_webapp_cdn[0].domain_name}" : "https://placeholder"
        },
        {
          name  = "AI_AGENT_URL"
          value = var.env_AI_AGENT_URL
        },
        {
          name  = "AUTH_MANAGER_URL"
          value = var.env_AUTH_MANAGER_URL
        },
        {
          name  = "CELL_API_URL"
          value = var.env_CELL_API_URL
        },
        {
          name  = "ENTITY_CORE_URL"
          value = var.env_ENTITY_CORE_URL
        },
        {
          name  = "NOTEBOOK_API_URL"
          value = var.env_NOTEBOOK_API_URL
        },
        {
          name  = "OBI_ONE_URL"
          value = var.env_OBI_ONE_URL
        },
        {
          name  = "SMALL_SCALE_SIMULATOR_URL"
          value = var.env_SMALL_SCALE_SIMULATOR_URL
        },
        {
          name  = "THUMBNAIL_API_URL"
          value = var.env_THUMBNAIL_API_URL
        },
        {
          name  = "VIRTUAL_LAB_API_URL"
          value = var.env_VIRTUAL_LAB_API_URL
        },
      ]
      secrets = [
        {
          name      = "KEYCLOAK_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:client_secret_${var.key}::"
        },
        {
          name      = "GITHUB_TOKEN"
          valueFrom = "${var.secrets_arn}:GITHUB_TOKEN::"
        },
        {
          name      = "NEXTAUTH_SECRET"
          valueFrom = "${var.secrets_arn}:nextauth_secret::"
        },
        {
          name      = "MAILCHIMP_API_KEY"
          valueFrom = "${var.secrets_arn}:MAILCHIMP_API_KEY::"
        },
        {
          name      = "MAILCHIMP_AUDIENCE_ID"
          valueFrom = "${var.secrets_arn}:MAILCHIMP_AUDIENCE_ID::"
        },
        {
          name      = "MAILCHIMP_API_SERVER"
          valueFrom = "${var.secrets_arn}:MAILCHIMP_API_SERVER::"
        },
        {
          name      = "SENTRY_DSN"
          valueFrom = "${var.secrets_arn}:SENTRY_DSN::"
        },
        {
          name      = "GITHUB_FEEDBACK_PROJECT_ID"
          valueFrom = "${var.secrets_arn}:GITHUB_FEEDBACK_PROJECT_ID::"
        },
        {
          name      = "GITHUB_FEEDBACK_TOKEN"
          valueFrom = "${var.secrets_arn}:GITHUB_FEEDBACK_TOKEN::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "core_webapp"
        }
      }
    }
  ])

  cpu                      = local.cpu
  memory                   = local.memory
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_core_webapp_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_core_webapp_task_role[0].arn

  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_ecs_service" "core_webapp_ecs_service" {
  count = var.ecs_number_of_containers > 0 ? 1 : 0

  name            = "core_webapp_${var.key}_ecs_service"
  cluster         = aws_ecs_cluster.core_webapp.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.core_webapp_ecs_definition[0].arn
  desired_count   = var.ecs_number_of_containers

  load_balancer {
    target_group_arn = aws_lb_target_group.core_webapp_private.arn
    container_name   = "core_webapp"
    container_port   = 8000
  }


  network_configuration {
    security_groups  = [aws_security_group.core_webapp_ecs_task.id]
    subnets          = [aws_subnet.core_webapp.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.core_webapp,
    aws_iam_role.ecs_core_webapp_task_execution_role, # wrong?
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "ecs_core_webapp_task_execution_role" {
  count = var.ecs_number_of_containers > 0 ? 1 : 0
  name  = "core_webapp_${var.key}-ecsTaskExecutionRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_iam_role_policy_attachment" "ecs_core_webapp_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_core_webapp_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_core_webapp_task_role" {
  count = var.ecs_number_of_containers > 0 ? 1 : 0
  name  = "core_webapp_${var.key}-ecsTaskRole"

  assume_role_policy = <<EOF
{
 "Version": "2012-10-17",
 "Statement": [
   {
     "Action": "sts:AssumeRole",
     "Principal": {
       "Service": "ecs-tasks.amazonaws.com"
     },
     "Effect": "Allow",
     "Sid": ""
   }
 ]
}
EOF
  tags = {
    SBO_Billing = var.sbo_billing_tag
  }
}

resource "aws_iam_role_policy_attachment" "ecs_core_webapp_secrets_access_policy_attachment" {
  count      = var.ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_core_webapp_task_execution_role[0].name
  policy_arn = aws_iam_policy.sbo_core_webapp_secrets_access.arn
}
