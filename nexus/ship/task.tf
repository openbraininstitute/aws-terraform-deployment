locals {
  log_group_name = "nexus_ship"
  ship_cpu       = 4096
  ship_memory    = 8192
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
      memory = local.ship_memory
      cpu    = local.ship_cpu

      environment = [
        {
          name  = "POSTGRES_HOST"
          value = var.postgres_host
        },
        {
          name  = "TARGET_BASE_URI"
          value = var.target_base_uri
        },
        {
          name  = "POSTGRES_DATABASE"
          value = var.postgres_database
        },
        {
          name  = "POSTGRES_USERNAME"
          value = var.postgres_username
        },
        {
          name  = "TARGET_BUCKET"
          value = var.target_bucket
        },
        {
          name  = "IMPORT_BUCKET"
          value = aws_s3_bucket.nexus_ship.id
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

      command = [
        "run",
        "--s3",
        "--config",
        "ship.conf",
        "--path",
        "path/to/import/file/in/s3"
      ],

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
}

resource "aws_cloudwatch_log_group" "nexus_ship" {
  name              = local.log_group_name
  skip_destroy      = false
  retention_in_days = 7
  kms_key_id        = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key
}
