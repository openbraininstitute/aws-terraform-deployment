resource "aws_cloudwatch_log_group" "virtual_lab_manager" {
  # TODO check if the logs can be encrypted
  name              = var.virtual_lab_manager_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "virtual_lab_manager"
    SBO_Billing = "virtual_lab_manager"
  }
}

# TODO check: not used?
resource "aws_cloudwatch_log_group" "virtual_lab_manager_ecs" {
  # TODO check if the logs can be encrypted
  name              = "virtual_lab_manager_ecs"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "virtual_lab_manager"
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_ecs_cluster" "virtual_lab_manager" {
  name = "virtual_lab_manager_ecs_cluster"

  tags = {
    Application = "virtual_lab_manager"
    SBO_Billing = "virtual_lab_manager"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "virtual_lab_manager_ecs_task" {
  name        = "virtual_lab_manager_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO core webapp"

  tags = {
    Name        = "virtual_lab_manager_secgroup"
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_vpc_security_group_ingress_rule" "virtual_lab_manager_allow_port_8000" {
  security_group_id = aws_security_group.virtual_lab_manager_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8000 http"

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_vpc_security_group_egress_rule" "virtual_lab_manager_allow_outgoing_tcp" {
  security_group_id = aws_security_group.virtual_lab_manager_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_vpc_security_group_egress_rule" "virtual_lab_manager_allow_outgoing_udp" {
  security_group_id = aws_security_group.virtual_lab_manager_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_ecs_task_definition" "virtual_lab_manager_ecs_definition" {
  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0

  family       = "virtual_lab_manager_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      cpu         = 256
      memory      = 512
      networkMode = "awsvpc"
      family      = "virtuallabmanager"
      essential   = true
      image       = var.virtual_lab_manager_docker_image_url
      name        = "virtual_lab_manager"

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
        command     = ["CMD-SHELL", "exit 0"] // TODO: add a proper health check.
        interval    = 60
        timeout     = 5
        startPeriod = 30
        retries     = 3
      }
      environment = [
        {
          name  = "DEBUG"
          value = "true"
        },
        {
          name  = "BASE_PATH"
          value = "${var.virtual_lab_manager_base_path}"
        },
        {
          name  = "KEYCLOAK_SERVER_URL"
          value = "${var.keycloak_server_url}"
        },
        {
          name  = "KEYCLOAK_REALM_NAME"
          value = "SBO"
        },
        {
          name  = "KEYCLOAK_USER_REALM_NAME"
          value = "master"
        },
        {
          name  = "POSTGRES_HOST"
          value = aws_db_instance.virtual_lab_manager.address
        },
        {
          name  = "POSTGRES_PORT"
          value = "5432"
        },
        {
          name  = "POSTGRES_USER"
          value = var.virtual_lab_manager_postgres_user
        },
        {
          name  = "POSTGRES_DB"
          value = var.virtual_lab_manager_postgres_db
        }
      ]
      secrets = [
        {
          name      = "KEYCLOAK_ADMIN_USERNAME"
          valueFrom = "${var.virtual_lab_manager_secrets_arn}:keycloak_admin_username::"
        },
        {
          name      = "KEYCLOAK_ADMIN_PASSWORD"
          valueFrom = "${var.virtual_lab_manager_secrets_arn}:keycloak_admin_password::"
        },
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.virtual_lab_manager_secrets_arn}:database_password::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.virtual_lab_manager_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "virtual_lab_manager"
        }
      }
    }
  ])

  cpu                      = 256
  memory                   = 512
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_virtual_lab_manager_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_virtual_lab_manager_task_role[0].arn

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_ecs_service" "virtual_lab_manager_ecs_service" {
  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0

  name            = "virtual_lab_manager_ecs_service"
  cluster         = aws_ecs_cluster.virtual_lab_manager.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.virtual_lab_manager_ecs_definition[0].arn
  desired_count   = var.virtual_lab_manager_ecs_number_of_containers

  load_balancer {
    target_group_arn = aws_lb_target_group.virtual_lab_manager.arn
    container_name   = "virtual_lab_manager"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.virtual_lab_manager_ecs_task.id]
    subnets          = [aws_subnet.core_svc_a.id, aws_subnet.core_svc_b.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.virtual_lab_manager,
    aws_iam_role.ecs_virtual_lab_manager_task_execution_role,
  ]

  force_new_deployment = true

  lifecycle {
    ignore_changes = [desired_count]
  }

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_iam_role" "ecs_virtual_lab_manager_task_execution_role" {
  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0
  name  = "virtual_lab_manager-ecsTaskExecutionRole"

  assume_role_policy = <<-EOT
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
  EOT

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_virtual_lab_manager_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_virtual_lab_manager_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_virtual_lab_manager_task_role" {
  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0
  name  = "virtual_lab_manager-ecsTaskRole"

  assume_role_policy = <<-EOT
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
  EOT

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_virtual_lab_manager_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.ecs_virtual_lab_manager_task_execution_role[0].name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn

  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role_policy_attachment" "ecs_virtual_lab_manager_secrets_access_policy_attachment" {
  role       = aws_iam_role.ecs_virtual_lab_manager_task_execution_role[0].name
  policy_arn = aws_iam_policy.virtual_lab_manager_secrets_access.arn

  count = var.virtual_lab_manager_ecs_number_of_containers > 0 ? 1 : 0
}