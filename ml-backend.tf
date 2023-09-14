################################################################################
# Resource definitions
################################################################################
resource "aws_cloudwatch_log_group" "ml_backend" {
  name              = "ml_backend"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "ml_backend"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_security_group" "ml_backend_ecs_task" {
  name        = "ml_backend_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for ML Reader webapp"

  tags = {
    Name        = "ml_backend_secgroup"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ml_backend_allow_port_3000" {
  security_group_id = aws_security_group.ml_backend_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 http"

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_egress_rule" "ml_backend_allow_outgoing" {
  security_group_id = aws_security_group.ml_backend_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow everything"

  tags = {
    SBO_Billing = "machinelearning"
  }
}


resource "aws_ecs_task_definition" "ml_backend_ecs_definition" {
  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0

  family       = "ml_backend_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 4096
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "ml_backend"
      essential   = true
      image       = var.ml_backend_docker_image_url
      name        = "ml_backend"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8080
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
     environment = [
        {
          name  = "FOO"
          value = "BAR"
        },
        {
          name  = "BAZ"
          value = "BAR"
        }
      ]
      secrets = [
        {
          name      = "ABC"
          valueFrom = "${var.bbp_ml_secrets_arn}:ABC::" # to be created
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.ml_backend_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_backend"
        }
      }
    }
  ])

  memory                   = 4096
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_ml_backend_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_ml_backend_task_role[0].arn

  tags = {
    SBO_Billing = "machinelearning"
  }
}
