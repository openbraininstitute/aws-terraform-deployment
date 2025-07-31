#tfsec:ignore:aws-ecs-enable-in-transit-encryption
resource "aws_ecs_task_definition" "sbo_keycloak_task" {
  family                   = "keycloak-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # Use AWS VPC networking mode
  cpu                      = var.keycloak_task_size.cpu
  memory                   = var.keycloak_task_size.memory
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  container_definitions = jsonencode([
    {
      name      = "keycloak-container"
      image     = "quay.io/keycloak/keycloak:26.2.4"
      cpu       = var.keycloak_task_size.cpu
      memory    = var.keycloak_task_size.memory
      command   = ["start"]
      essential = true
      portMappings = [
        {
          name          = "keycloak-container-port-tcp"
          containerPort = var.keycloak_port
          hostPort      = var.keycloak_port
          protocol      = "tcp"
        },
        {
          name          = "keycloak-management-port-tcp"
          containerPort = var.keycloak_management_port
          hostPort      = var.keycloak_management_port
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command = [
          "CMD-SHELL",
          "exec 3<>/dev/tcp/127.0.0.1/${var.keycloak_management_port};echo -e 'GET /health/ready HTTP/1.1\r\nhost: http://localhost\r\nConnection: close\r\n\r\n' >&3;if [ $? -eq 0 ]; then echo 'Healthcheck Successful';exit 0;else echo 'Healthcheck Failed';exit 1;fi;"
        ]
        interval    = 30
        timeout     = 5
        startPeriod = 120
        retries     = 3
      }
      environment = [
        {
          name  = "KC_HOSTNAME"
          value = var.domain_name
        },
        {
          name  = "KC_DB"
          value = aws_db_instance.keycloak_database.engine
        },
        {
          name  = "KC_DB_URL_HOST"
          value = aws_db_instance.keycloak_database.address
        },
        {
          name  = "KC_DB_URL_DATABASE"
          value = aws_db_instance.keycloak_database.db_name
        },
        {
          name  = "KC_DB_USERNAME"
          value = aws_db_instance.keycloak_database.username
        },
        {
          name  = "KC_HEALTH_ENABLED"
          value = "true"
        },
        {
          name  = "KC_HTTP_ENABLED"
          value = "true"
        },
        {
          name  = "KC_HTTP_RELATIVE_PATH"
          value = "/auth"
        },
        {
          name  = "KC_HTTP_PORT"
          value = "${tostring(var.keycloak_port)}"
        },
        {
          name  = "KC_METRICS_ENABLED"
          value = "true"
        },
        {
          name  = "KC_EVENT_METRICS_USER_ENABLED"
          value = "true"
        },
        {
          name  = "KC_HTTP_METRICS_HISTOGRAMS_ENABLED"
          value = "true"
        },
        {
          name  = "KC_CACHE_METRICS_HISTOGRAMS_ENABLED"
          value = "true"
        },
        {
          name  = "KC_PROXY_HEADERS"
          value = "xforwarded"
        },
        {
          name  = "KEYCLOAK_ADMIN"
          value = "admin"
        },
        {
          name  = "JAVA_OPTS_APPEND"
          value = "-XX:MaxRAMPercentage=75.0"
        },
        {
          name  = "PROXY_ADDRESS_FORWARDING"
          value = "true"
        },
      ]
      secrets = [
        {
          name      = "KEYCLOAK_ADMIN_PASSWORD"
          valueFrom = var.keycloak_secrets_arn
        },
        {
          name      = "KC_DB_PASSWORD"
          valueFrom = var.keycloak_secrets_arn
        }
      ]
      mountPoints = [
        {
          sourceVolume  = "keycloak-theme-volume"
          containerPath = "/opt/keycloak/themes"
          readOnly      = false
        },
        {
          sourceVolume  = "keycloak-providers-volume"
          containerPath = "/opt/keycloak/providers"
          readOnly      = false
        }
      ]
      volumesFrom = [],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.keycloak_ecs_task.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      systemControls = []
    },
    {
      name  = "aws-collector"
      image = "public.ecr.aws/aws-observability/aws-otel-collector:v0.43.3"
      command = [
        "--config=/etc/ecs/otel-agent-config.yaml"
      ]
      essential = false
      mountPoints = [
        {
          sourceVolume  = "otel-config-volume"
          containerPath = "/etc/ecs/"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.keycloak_aws_otel_collector.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
      healthcheck = {
        command = [
          "/healthcheck"
        ]
        interval = 5
        retries  = 2
        timeout  = 3
      }
      dependsOn = [
        {
          containerName = "keycloak-otel-agent-config"
          condition     = "COMPLETE"
        }
      ]
    },
    {
      name      = "keycloak-otel-agent-config"
      image     = "bash"
      essential = false
      command = [
        "sh",
        "-c",
        <<-EOT
          echo $OTEL_AGENT_CONFIG | base64 -d - | tee /etc/ecs/otel-agent-config.yaml && sed -i -e "s;\$${KEYCLOAK_MANAGEMENT_PORT};$KEYCLOAK_MANAGEMENT_PORT;g" -e "s;\$${AWS_REGION};$AWS_REGION;g" -e "s;\$${PROMETHEUS_ENDPOINT};$PROMETHEUS_ENDPOINT;g" /etc/ecs/otel-agent-config.yaml
        EOT
      ]
      environment = [
        {
          name  = "OTEL_AGENT_CONFIG"
          value = base64encode(file("${path.module}/otel-agent-config.yaml.tmpl"))
        },
        {
          name  = "KEYCLOAK_MANAGEMENT_PORT"
          value = "${tostring(var.keycloak_management_port)}"
        },
        {
          name  = "AWS_REGION"
          value = data.aws_region.current.name
        },
        {
          name  = "PROMETHEUS_ENDPOINT"
          value = "${aws_prometheus_workspace.keycloak-managed-prometheus-workspace.prometheus_endpoint}api/v1/remote_write"
        },
      ]
      mountPoints = [
        {
          sourceVolume  = "otel-config-volume"
          containerPath = "/etc/ecs/"
          readOnly      = false
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.keycloak_aws_otel_collector.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  volume {
    name = "keycloak-theme-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.keycloak-theme.id
      root_directory = "/"
    }
  }
  volume {
    name = "keycloak-providers-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.keycloak-providers.id
      root_directory = "/"
    }
  }

  volume {
    name = "otel-config-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.otel-config.id
      root_directory = "/"
    }
  }

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_cloudwatch_log_group" "keycloak_ecs_task" {
  name              = "keycloak-task"
  retention_in_days = 180
  skip_destroy      = false

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_cloudwatch_log_group" "keycloak_aws_otel_collector" {
  name              = "keycloak-aws-otel-collector"
  retention_in_days = 14
  skip_destroy      = false

  tags = {
    SBO_Billing = "keycloak"
  }
}
