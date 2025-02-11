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
  container_definitions    = <<TASK_DEFINITION
  [
        {
            "name": "keycloak-container",
            "image": "keycloak/keycloak:25.0.6",
            "cpu": ${var.keycloak_task_size.cpu},
            "memory": ${var.keycloak_task_size.memory},
            "portMappings": [
                {
                    "name": "keycloak-container-port-tcp",
                    "containerPort": ${var.keycloak_port},
                    "hostPort": ${var.keycloak_port},
                    "protocol": "tcp"
                },
                {
                    "name": "keycloak-management-port-tcp",
                    "containerPort": ${var.keycloak_management_port},
                    "hostPort": ${var.keycloak_management_port},
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "start"
            ],
            "environment": [
                {
                    "name": "KC_HOSTNAME",
                    "value": "${var.preferred_hostname}"
                },
                {
                    "name": "KC_DB",
                    "value": "${aws_db_instance.keycloak_database.engine}"
                },
                {
                    "name": "KC_DB_URL_HOST",
                    "value": "${aws_db_instance.keycloak_database.address}"
                },
                {
                    "name": "KC_DB_URL_DATABASE",
                    "value": "${aws_db_instance.keycloak_database.db_name}"
                },
                {
                    "name": "KC_DB_USERNAME",
                    "value": "${aws_db_instance.keycloak_database.username}"
                },
	        {
 	            "name": "KC_HEALTH_ENABLED",
	            "value": "true"
	        },
	        {
                    "name": "KC_HTTP_ENABLED",
	            "value": "true"
	        },
	        {
                    "name": "KC_HTTP_RELATIVE_PATH",
	            "value": "/auth"
	        },
	        {
                    "name": "KC_HTTP_PORT",
                    "value": "${var.keycloak_port}"
	        },
                {
                    "name": "KC_PROXY",
                    "value": "edge"
                },
                {
                    "name": "KEYCLOAK_ADMIN",
                    "value": "admin"
                },
                {
                    "name": "JAVA_OPTS_APPEND",
                    "value": "-Xms512m -Xmx2g"
                },
	        {
	            "name": "PROXY_ADDRESS_FORWARDING",
	            "value": "true"
	        }
            ],
            "secrets": [
	        {
                    "name": "KEYCLOAK_ADMIN_PASSWORD",
                    "valueFrom": "${var.keycloak_secrets_arn}"
	        },
	        {
                    "name": "KC_DB_PASSWORD",
                    "valueFrom": "${var.keycloak_secrets_arn}"
	        }
            ],
            "mountPoints": [
                {
                    "sourceVolume": "keycloak-theme-volume",
                    "containerPath": "/opt/keycloak/themes",
                    "readOnly": false
                },
                {
                    "sourceVolume": "keycloak-providers-volume",
                    "containerPath": "/opt/keycloak/providers",
                    "readOnly": false
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/keycloak-task",
                    "awslogs-region": "${data.aws_region.current.name}",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            },
            "systemControls": []
        }
    ]
    TASK_DEFINITION
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
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

  tags = {
    SBO_Billing = "keycloak"
  }
}
