# Cluster Definition

resource "aws_ecs_cluster" "thumbnail_generation_api_cluster" {
  name = "thumbnail_generation_api_cluster"

  tags = {
    Application = "thumbnail_generation_api"
    SBO_Billing = "thumbnail_generation_api"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }


}



# Task Definition
resource "aws_ecs_task_definition" "thumbnail_generation_api_task_definition" {
  family                   = "thumbnail-generation-api-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]

  # Container definition for FastAPI
  container_definitions = jsonencode(
    [
      {
        name  = "thumbnail-generation-api-container",
        image = var.thumbnail_generation_api_docker_image_url,
        repositoryCredentials = {
          credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
        }
        essential = true,
        portMappings = [
          {
            containerPort = 8080,
            protocol      = "tcp"
          }
        ],
        environment = [
          {
            name  = "WHITELISTED_CORS_URLS",
            value = "http:localhost:3000,https://bbp.epfl.ch"
          }
        ]
      },
      {
        name      = "nginx-reverse-proxy-container",
        image     = "nginx:latest",
        essential = true,
        portMappings = [
          {
            containerPort = 80,
            protocol      = "tcp"
          }
        ],
        mountPoints = [
          {
            containerPath = "/etc/nginx",
            sourceVolume  = "nginx-reverse-proxy-volume"
          }
        ]
      }
  ])

  # Volume definition for EFS
  volume {
    name = "nginx-reverse-proxy-volume"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.thumbnail_generation_api_efs_instance.id
      root_directory     = "/etc/nginx"
      transit_encryption = "ENABLED"
    }
  }
}

# Service
resource "aws_ecs_service" "thumbnail_generation_api_service" {
  name            = "thumbnail-generation-api-service"
  cluster         = aws_ecs_cluster.thumbnail_generation_api_cluster.id
  task_definition = aws_ecs_task_definition.thumbnail_generation_api_task_definition.arn
  desired_count   = 1

  # Load Balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.thumbnail_generation_api_tg.arn
    container_name   = "nginx-reverse-proxy-container"
    container_port   = 80
  }
}