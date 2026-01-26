locals {
  name           = "secret-sharing-svc"
  service_name   = "secret-sharing-svc-service"
  cluster_name   = "secret-sharing-svc-cluster"
  container_name = "secret-sharing-svc-container"
}

resource "aws_ecs_cluster" "secret-sharing-svc-cluster" {
  name = local.cluster_name
  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}

resource "aws_ecs_service" "secret-sharing-svc-service" {
  name            = local.service_name
  cluster         = aws_ecs_cluster.secret-sharing-svc-cluster.id
  task_definition = aws_ecs_task_definition.secret_sharing_svc_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    subnets         = [var.secret_sharing_svc_subnet]
    security_groups = [aws_security_group.secret_sharing_svc_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.secret_sharing_svc_target_group.arn
    container_name   = local.container_name
    container_port   = var.secret_sharing_svc_port
  }

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
  propagate_tags = "SERVICE"
}

resource "aws_ecs_task_definition" "secret_sharing_svc_task" {
  family                   = local.name
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = var.secret_sharing_svc_task_size.cpu
  memory                   = var.secret_sharing_svc_task_size.memory
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  volume {
    name = "tmp"
  }

  container_definitions = jsonencode([
    {
      name                   = local.container_name
      image                  = "ghcr.io/corentinth/enclosed:1.16.0-rootless"
      readonlyRootFilesystem = true
      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
        }
      ]
      portMappings = [
        {
          name          = "secret-sharing-svc-port-tcp"
          containerPort = var.secret_sharing_svc_port
          hostPort      = var.secret_sharing_svc_port
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "PUBLIC_IS_SETTING_NO_EXPIRATION_ALLOWED"
          value = "false"
        },
        {
          name  = "STORAGE_DRIVER_FS_LITE_PATH"
          value = "/tmp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.secret_sharing_svc.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_task_execution_role.arn

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}

resource "aws_cloudwatch_log_group" "secret_sharing_svc" {
  name              = local.name
  retention_in_days = 7
  skip_destroy      = false

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}
