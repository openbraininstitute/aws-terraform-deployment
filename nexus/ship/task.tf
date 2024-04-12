locals {
  log_group_name = "nexus_ship"
  ship_cpu       = 256
  ship_memory    = 512
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "nexus_ship" {
  family       = "nexus_ship_task_family"
  network_mode = "awsvpc"

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  container_definitions = jsonencode([
    {
      memory  = local.ship_memory
      cpu     = local.ship_cpu
      command = ["config"]
      environment = [
        {
          name  = "POSTGRES_HOST"
          value = var.postgres_host
        }
      ]
      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.nexus_secrets_arn}:postgres_password::"
        },
      ]
      networkMode = "awsvpc"
      essential   = true
      image       = "bluebrain/nexus-ship:latest"
      name        = "nexus_ship"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_ship"
        }
      }
    }
  ])

  cpu                      = local.ship_cpu
  memory                   = local.ship_memory
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = aws_iam_role.nexus_ship_ecs_task.arn

  tags = {
    SBO_Billing = "nexus_ship"
  }
}

resource "aws_cloudwatch_log_group" "nexus_ship" {
  name              = local.log_group_name
  skip_destroy      = false
  retention_in_days = 7
  kms_key_id        = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}