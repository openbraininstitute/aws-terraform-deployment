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

resource "aws_iam_role" "thumbnail_generation_api_ecs_task_execution_role" {
  name = "thumbnail_generation_api-ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}


resource "aws_iam_role_policy_attachment" "thumbnail_generation_api_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.thumbnail_generation_api_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "thumbnail_generation_api_ecs_task_role" {
  name = "thumbnail_generation_api-ecsTaskRole"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Action" = "sts:AssumeRole",
        "Principal" = {
          "Service" = "ecs-tasks.amazonaws.com"
        },
        "Effect" = "Allow",
        "Sid"    = ""
      }
    ]
  })
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_iam_role_policy_attachment" "thumbnail_generation_api_ecs_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.thumbnail_generation_api_ecs_task_execution_role.name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_security_group" "thumbnail_generation_api_sec_group" {
  name        = "thumbnail_generation_api_sec_group"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for thumbnail generation api"

  tags = {
    Name        = "thumbnail_generation_api_secgroup"
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "thumbnail_generation_api_allow_port_8080" {
  security_group_id = aws_security_group.thumbnail_generation_api_sec_group.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 http"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "thumbnail_generation_api_allow_port_80" {
  security_group_id = aws_security_group.thumbnail_generation_api_sec_group.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 80 http"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "thumbnail_generation_api_allow_outgoing_tcp" {
  security_group_id = aws_security_group.thumbnail_generation_api_sec_group.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all TCP"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "thumbnail_generation_api_allow_outgoing_udp" {
  security_group_id = aws_security_group.thumbnail_generation_api_sec_group.id
  ip_protocol       = "udp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all UDP"
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}


# Task Definition
resource "aws_ecs_task_definition" "thumbnail_generation_api_task_definition" {
  family                   = "thumbnail-generation-api-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.thumbnail_generation_api_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.thumbnail_generation_api_ecs_task_role.arn
  memory                   = 4096
  cpu                      = 2048


  # Container definition for FastAPI
  container_definitions = jsonencode(
    [
      {
        name  = "thumbnail-generation-api-container",
        image = var.thumbnail_generation_api_docker_image_url,
        repositoryCredentials = {
          credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
        },
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
        ],
        memory = 2048
        cpu    = 1024
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
        ],
        memory = 2048
        cpu    = 1024
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
  name                 = "thumbnail-generation-api-service"
  cluster              = aws_ecs_cluster.thumbnail_generation_api_cluster.id
  task_definition      = aws_ecs_task_definition.thumbnail_generation_api_task_definition.arn
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"


  # Load Balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.thumbnail_generation_api_tg.arn
    container_name   = "nginx-reverse-proxy-container"
    container_port   = 80
  }

  network_configuration {
    security_groups  = [aws_security_group.thumbnail_generation_api_sec_group.id]
    subnets          = [aws_subnet.thumbnail_generation_api.id]
    assign_public_ip = false
  }
}