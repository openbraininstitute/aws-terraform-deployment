locals {
  delta_nginx_log_group_name = "delta-nginx"
  nexus_cpu                      = 512
  nexus_memory                   = 1024
  instance_name = "delta-nginx"
}

data "aws_region" "current" {}

resource "aws_iam_role" "delta_nginx_ecs_task" {
  name = "${local.instance_name}-ecsTaskRole"

  assume_role_policy = <<EOF
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
EOF
}

resource "aws_ecs_task_definition" "delta_nginx_ecs_definition" {
  family       = local.instance_name
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "delta-nginx"
      memory = local.nexus_memory
      cpu    = local.nexus_cpu
      networkMode = "awsvpc"
      essential   = true
      image       = "nginx:mainline-alpine"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          name          = local.instance_name
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
          sourceVolume  = "efs-delta-nginx-config"
          containerPath = "/etc/nginx"
          readOnly      = true
        }
      ]
      dependsOn = [
        {
          containerName = "delta-nginx-config"
          condition     = "COMPLETE"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.delta_nginx_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "delta_nginx"
        }
      }
    },
    {
      name      = "delta-nginx-config"
      image     = "bash"
      essential = false
      command = [
        "sh",
        "-c",
        <<-EOT
          echo $NGINX_CONFIG  | base64 -d - | tee /etc/nginx/nginx.conf
        EOT
      ],
      environment = [
        {
          name  = "NGINX_CONFIG"
          value = base64encode(file("${path.module}/nginx.conf"))
        }
      ],
      mountPoints = [
        {
          sourceVolume  = "efs-delta-nginx-config"
          containerPath = "/etc/nginx"
        },
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.delta_nginx_log_group_name
          awslogs-region        = data.aws_region.current.name
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "delta_nginx_config"
        }
      },
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = var.ecs_task_execution_role_arn
  task_role_arn            = aws_iam_role.delta_nginx_ecs_task.arn

  volume {
    name = "efs-delta-nginx-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.delta_nginx.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.delta_config.id
        iam             = "DISABLED"
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "nexus_app" {
  # TODO check if the logs can be encrypted
  name              = local.delta_nginx_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = local.instance_name
  }
}