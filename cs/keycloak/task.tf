#tfsec:ignore:aws-ecs-enable-in-transit-encryption
resource "aws_ecs_task_definition" "sbo_keycloak_task" {
  family                   = "keycloak-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc" # Use AWS VPC networking mode
  cpu                      = 2048
  memory                   = 4096
  container_definitions    = <<TASK_DEFINITION
  [
        {
            "name": "keycloak-container",
            "image": "keycloak/keycloak:21.1.1",
            "cpu": 2048,
            "memory": 4096,
            "portMappings": [
                {
                    "name": "keycloak-container-8081-tcp",
                    "containerPort": 8081,
                    "hostPort": 8081,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "start"
            ],
            "environment": [
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
                    "name": "KC_DB_PASSWORD",
	            "value": "${data.aws_secretsmanager_secret_version.keycloak_database_password.secret_string}"
	        },
                {
                    "name": "KC_HOSTNAME_STRICT",
                    "value": "false"
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
                    "value": "8081"
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
                    "name": "KEYCLOAK_ADMIN_PASSWORD",
	            "value": "${data.aws_secretsmanager_secret_version.keycloak_database_password.secret_string}"
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
            "mountPoints": [
                {
                    "sourceVolume": "keycloak-volume",
                    "containerPath": "/docker-keycloak",
                    "readOnly": false
                },
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
                    "awslogs-region": "${var.aws_region}",
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
    name = "keycloak-volume"
    efs_volume_configuration {
      file_system_id = aws_efs_file_system.keycloakfs.id
      root_directory = "/"
    }
  }
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
