locals {
  nexus_delta_app_log_group_name = var.delta_instance_name
  nexus_cpu                      = var.delta_cpu
  nexus_memory                   = var.delta_memory
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "nexus_app_ecs_definition" {
  family       = var.delta_instance_name
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "delta"
      memory = local.nexus_memory
      cpu    = local.nexus_cpu
      command = [
        "/bin/bash",
        "-c",
        "/opt/docker/bin/delta-app",
        "-Dakka.http.client.parsing.max-content-length=100g",
        "-Dakka.http.host-connection-pool.max-open-requests=128",
        "-Dakka.http.host-connection-pool.response-entity-subscription-timeout=15.seconds",
        "-Dakka.http.server.parsing.max-content-length=2MiB",
        "-Dlogback.configurationFile=/opt/delta-config/logback.xml"
      ]
      environment = [
        {
          name  = "KAMON_ENABLED"
          value = "false"
        },
        {
          name  = "DELTA_PLUGINS"
          value = "/opt/docker/plugins/"
        },
        {
          name  = "DELTA_EXTERNAL_CONF"
          value = "/opt/delta-config/delta.conf"
        },
        {
          name  = "POSTGRES_HOST"
          value = var.postgres_host
        },
        {
          name  = "POSTGRES_READER_ENDPOINT"
          value = var.postgres_reader_host
        },
        {
          name  = "ELASTICSEARCH_ENDPOINT"
          value = var.elasticsearch_endpoint
        },
        {
          name  = "BLAZEGRAPH_ENDPOINT"
          value = var.blazegraph_endpoint
        },
        {
          name  = "BLAZEGRAPH_COMPOSITE_ENDPOINT"
          value = var.blazegraph_composite_endpoint
        }
      ]
      secrets = [
        {
          name      = "POSTGRES_PASSWORD"
          valueFrom = "${var.nexus_secrets_arn}:postgres_password::"
        },
        {
          name      = "ELASTICSEARCH_PASSWORD"
          valueFrom = "${var.elastic_password_arn}:password::"
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
          containerPath = "/opt/delta-config"
          readOnly      = true
        },
        {
          sourceVolume  = "efs-nexus-disk-storage"
          containerPath = "/opt/disk-storage"
          readOnly      = false
        },
      ]
      dependsOn = [
        {
          containerName = "delta-config"
          condition     = "COMPLETE"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.nexus_delta_app_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_delta"
        }
      }
    },
    {
      name      = "delta-config"
      image     = "bash"
      essential = false
      command = [
        "sh",
        "-c",
        <<-EOT
          echo $DELTA_CONFIG  | base64 -d - | tee /opt/delta-config/delta.conf && \
          echo $LOGBACK_CONFIG | base64 -d - | tee /opt/delta-config/logback.xml && \
          wget $GITHUB_SEARCH_CONFIG_BASE/construct-query.sparql -O /opt/delta-config/construct-query.sparql && \
          wget $GITHUB_SEARCH_CONFIG_BASE/fields.json -O /opt/delta-config/fields.json && \
          wget $GITHUB_SEARCH_CONFIG_BASE/mapping.json -O /opt/delta-config/mapping.json && \
          wget $GITHUB_SEARCH_CONFIG_BASE/resource-types.json -O /opt/delta-config/resource-types.json && \
          wget $GITHUB_SEARCH_CONFIG_BASE/search-context.json -O /opt/delta-config/search-context.json && \
          wget $GITHUB_SEARCH_CONFIG_BASE/settings.json -O /opt/delta-config/settings.json
        EOT
      ],
      environment = [
        {
          name  = "DELTA_CONFIG"
          value = base64encode(file("${path.module}/${var.delta_config_file}"))
        },
        {
          name  = "LOGBACK_CONFIG"
          value = base64encode(file("${path.module}/logback.xml"))
        },
        {
          name  = "GITHUB_SEARCH_CONFIG_BASE"
          value = "https://raw.githubusercontent.com/BlueBrain/nexus/${var.delta_search_config_commit}/tests/docker/config"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-nexus-app-config"
          containerPath = "/opt/delta-config"
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.nexus_delta_app_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_delta_config"
        }
      },
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
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
      file_system_id     = aws_efs_file_system.delta.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.delta_config.id
        iam             = "DISABLED"
      }
    }
  }
  volume {
    name = "efs-nexus-disk-storage"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.delta.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.disk_storage.id
        iam             = "DISABLED"
      }
    }
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
  }
}