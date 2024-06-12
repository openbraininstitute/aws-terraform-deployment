locals {
  nexus_delta_app_log_group_name = var.delta_instance_name
  nexus_cpu                      = var.delta_cpu
  nexus_memory                   = var.delta_memory
}

resource "aws_ecs_task_definition" "nexus_app_ecs_definition" {
  family       = var.delta_instance_name
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory = local.nexus_memory
      cpu    = local.nexus_cpu
      command = [
        "/bin/bash",
        "-c",
        "/opt/docker/bin/delta-app",
        "-Dakka.http.client.parsing.max-content-length=100g",
        "-Dakka.http.host-connection-pool.max-open-requests=128",
        "-Dakka.http.host-connection-pool.response-entity-subscription-timeout=15.seconds",
        "-Dakka.http.server.parsing.max-content-length=2MiB"
      ]
      environment = [
        {
          name  = "DELTA_PLUGINS"
          value = "/opt/docker/plugins/"
        },
        {
          name  = "DELTA_EXTERNAL_CONF"
          value = "/opt/appconf/delta.conf"
        },
        {
          name  = "POSTGRES_HOST"
          value = var.postgres_host
        },
        {
          name  = "POSTGRES_HOST_READ_REPLICA"
          value = var.postgres_host_read_replica
        },
        {
          name  = "ELASTICSEARCH_ENDPOINT"
          value = var.elasticsearch_endpoint
        },
        {
          name  = "BLAZEGRAPH_ENDPOINT"
          value = var.blazegraph_endpoint
        }
      ]
      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.nexus_secrets_arn}:postgres_password::"
        },
        {
          name      = "ELASTICSEARCH_PASSWORD"
          valueFrom = "${var.nexus_secrets_arn}:${var.elastic_password_key}::"
        },
        {
          name      = "REMOTE_STORAGE_PASSWORD"
          valueFrom = "${var.nexus_secrets_arn}:remote_storage_password::"
        },
        {
          name      = "DELEGATION_PRIVATE_KEY"
          valueFrom = "${var.nexus_secrets_arn}:delegation_private_key::"
        }
      ]
      networkMode = "awsvpc"
      essential   = true
      image       = var.nexus_delta_docker_image_url
      name        = var.delta_instance_name
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8080
          containerPort = 8080
          protocol      = "tcp"
          name          = var.delta_instance_name
        }
      ]
      volumesFrom = []
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      mountPoints = [
        {
          sourceVolume  = "efs-nexus-app-config"
          containerPath = "/opt/appconf"
          readOnly      = true
        },
        {
          sourceVolume  = "efs-nexus-search-config"
          containerPath = "/opt/search-config"
          readOnly      = true
        },
        {
          sourceVolume  = "efs-nexus-disk-storage"
          containerPath = "/opt/disk-storage"
          readOnly      = false
        },
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.nexus_delta_app_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_delta"
        }
      }
    }
  ])

  cpu                      = local.nexus_cpu
  memory                   = local.nexus_memory
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = aws_iam_role.nexus_delta_ecs_task.arn

  volume {
    name = "efs-nexus-app-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      root_directory     = "/opt/appconf"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "efs-nexus-search-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      root_directory     = "/opt/search-config"
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "efs-nexus-disk-storage"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      root_directory     = "/opt/disk-storage"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_cloudwatch_log_group" "nexus_app" {
  # TODO check if the logs can be encrypted
  name              = local.nexus_delta_app_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = var.delta_instance_name
    SBO_Billing = "nexus_app"
  }
}