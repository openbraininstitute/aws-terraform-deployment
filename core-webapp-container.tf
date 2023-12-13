resource "aws_cloudwatch_log_group" "core_webapp" {
  # TODO check if the logs can be encrypted
  name              = var.core_webapp_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "core_webapp"
    SBO_Billing = "core_webapp"
  }
}

# TODO check: not used?
resource "aws_cloudwatch_log_group" "core_webapp_ecs" {
  # TODO check if the logs can be encrypted
  name              = "core_webapp_ecs"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "core_webapp"
    SBO_Billing = "core_webapp"
  }
}

resource "aws_ecs_cluster" "core_webapp" {
  name = "core_webapp_ecs_cluster"

  tags = {
    Application = "core_webapp"
    SBO_Billing = "core_webapp"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "core_webapp_ecs_task" {
  name        = "core_webapp_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO core webapp"

  tags = {
    Name        = "core_webapp_secgroup"
    SBO_Billing = "core_webapp"
  }
}

resource "aws_vpc_security_group_ingress_rule" "core_webapp_allow_port_8000" {
  security_group_id = aws_security_group.core_webapp_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8000 http"
  tags = {
    SBO_Billing = "core_webapp"
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
    SBO_Billing = "core_webapp"
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
    SBO_Billing = "core_webapp"
  }
}

resource "aws_ecs_task_definition" "core_webapp_ecs_definition" {
  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0

  family       = "core_webapp_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 1024
      cpu         = 512
      networkMode = "awsvpc"
      family      = "sbocorewebapp"
      essential   = true
      image       = var.core_webapp_docker_image_url
      name        = "core_webapp"
      repositoryCredentials = {
        credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
      }
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
          name  = "DEBUG"
          value = "true"
        },
        {
          name  = "NEXTAUTH_URL"
          value = "https://sbo-core-webapp.shapes-registry.org/mmb-beta/api/auth"
        },
        {
          name  = "KEYCLOAK_ISSUER"
          value = "https://sboauth.epfl.ch/auth/realms/SBO"
        },
      ]
      secrets = [
        {
          name      = "KEYCLOAK_CLIENT_SECRET"
          valueFrom = "${var.sbo_core_webapp_secrets_arn}:cognito_client_secret::"
        },
        {
          name      = "NEXTAUTH_SECRET"
          valueFrom = "${var.sbo_core_webapp_secrets_arn}:nextauth_secret::"
        },
        {
          name      = "KEYCLOAK_CLIENT_ID"
          valueFrom = "${var.sbo_core_webapp_secrets_arn}:cognito_client_id::"
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.core_webapp_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "core_webapp"
        }
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_core_webapp_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_core_webapp_task_role[0].arn

  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_ecs_service" "core_webapp_ecs_service" {
  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0

  name            = "core_webapp_ecs_service"
  cluster         = aws_ecs_cluster.core_webapp.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.core_webapp_ecs_definition[0].arn
  desired_count   = var.core_webapp_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.core_webapp.arn
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
  #triggers = {
  #  redeployment = timestamp()
  #}
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_iam_role" "ecs_core_webapp_task_execution_role" {
  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0
  name  = "core_webapp-ecsTaskExecutionRole"

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
    SBO_Billing = "core_webapp"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_core_webapp_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_core_webapp_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_core_webapp_task_role" {
  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0
  name  = "core_webapp-ecsTaskRole"

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
    SBO_Billing = "core_webapp"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_core_webapp_task_role_dockerhub_policy_attachment" {
  count      = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_core_webapp_task_execution_role[0].name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "ecs_core_webapp_secrets_access_policy_attachment" {
  count      = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_core_webapp_task_execution_role[0].name
  policy_arn = aws_iam_policy.sbo_core_webapp_secrets_access.arn
}
