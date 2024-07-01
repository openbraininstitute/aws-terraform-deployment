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
        "-Dakka.http.server.parsing.max-content-length=2MiB"
      ]
      environment = [
        {
          name  = "DELTA_PLUGINS"
          value = "/opt/docker/plugins/"
        },
        {
          name  = "DELTA_EXTERNAL_CONF"
          value = "/opt/appconf/delta-from-terraform.conf"
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
        "echo $DELTA_CONFIG | base64 -d - | tee /opt/appconf/delta-from-terraform.conf && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/construct-query.sparql -O /opt/search-config/construct-query-from-terraform.sparql && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/fields.json -O /opt/search-config/fields-from-terraform.json && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/mapping.json -O /opt/search-config/mapping-from-terraform.json && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/resource-types.json -O /opt/search-config/resource-types-from-terraform.json && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/search-context.json -O /opt/search-config/search-context-from-terraform.json && wget https://raw.githubusercontent.com/BlueBrain/nexus/$COMMIT/tests/docker/config/settings.json -O /opt/search-config/settings-from-terraform.json",
      ],
      environment = [
        {
          name  = "DELTA_CONFIG"
          value = base64encode(file("${path.module}/delta.conf"))
        },
        {
          name  = "COMMIT"
          value = "${var.delta_search_config_commit}"
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-nexus-app-config"
          containerPath = "/opt/appconf"
        },
        {
          sourceVolume  = "efs-nexus-search-config"
          containerPath = "/opt/search-config"
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
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.appconf.id
        iam             = "DISABLED"
      }
    }
  }
  volume {
    name = "efs-nexus-search-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.search_config.id
        iam             = "DISABLED"
      }
    }
  }
  volume {
    name = "efs-nexus-disk-storage"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.disk_storage.id
        iam             = "DISABLED"
      }
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