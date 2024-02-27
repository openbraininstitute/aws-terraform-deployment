# Cluster Definition

resource "aws_ecs_cluster" "kg_inference_api_cluster" {
  name = "kg_inference_api_cluster"

  tags = {
    Application = "kg_inference_api"
    SBO_Billing = "kg_inference_api"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

resource "aws_iam_role" "kg_inference_api_ecs_task_execution_role" {
  name = "kg_inference_api-ecsTaskExecutionRole"

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
    SBO_Billing = "kg_inference_api"
  }
}


resource "aws_iam_role_policy_attachment" "kg_inference_api_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.kg_inference_api_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "kg_inference_api_ecs_task_role" {
  name = "kg_inference_api-ecsTaskRole"
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
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_iam_role_policy_attachment" "kg_inference_api_ecs_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.kg_inference_api_ecs_task_execution_role.name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_security_group" "kg_inference_api_sec_group" {
  name        = "kg_inference_api_sec_group"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for kg inference api"

  tags = {
    Name        = "kg_inference_api_secgroup"
    SBO_Billing = "kg_inference_api"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow ingress from within vpc"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow egress to within vpc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kg_inference_api_allow_port_8080" {
  security_group_id = aws_security_group.kg_inference_api_sec_group.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 http"
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_vpc_security_group_ingress_rule" "kg_inference_api_allow_port_80" {
  security_group_id = aws_security_group.kg_inference_api_sec_group.id

  ip_protocol = "tcp"
  from_port   = 80
  to_port     = 80
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 80 http"
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "kg_inference_api_allow_outgoing_tcp" {
  security_group_id = aws_security_group.kg_inference_api_sec_group.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all TCP"
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_vpc_security_group_egress_rule" "kg_inference_api_allow_outgoing_udp" {
  security_group_id = aws_security_group.kg_inference_api_sec_group.id
  ip_protocol       = "udp"
  from_port         = 0
  to_port           = 65535
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all UDP"
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}


# Task Definition
resource "aws_ecs_task_definition" "kg_inference_api_task_definition" {
  family                   = "kg-inference-api-task-definition"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.kg_inference_api_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.kg_inference_api_ecs_task_role.arn
  memory                   = 4096
  cpu                      = 2048


  # Container definition for FastAPI
  container_definitions = jsonencode(
    [
      {
        name  = "kg-inference-api-container",
        image = var.kg_inference_api_docker_image_url,
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
            name  = "BBP_NEXUS_ENDPOINT",
            value = "https://sbo-nexus-delta.shapes-registry.org/v1"
          },
          {
            name  = "ENVIRONMENT",
            value = "DEV"
          },
          {
            name  = "RULES_BUCKET",
            value = "bbp/inference-rules"
          },
          {
            name  = "DATAMODELS_BUCKET",
            value = "neurosciencegraph/datamodels"
          },
          {
            name  = "WHITELISTED_CORS_URLS",
            value = "http://localhost:3000,https://openbrainplatform.org"
          },
          {
            name  = "ES_RULE_VIEW",
            value = "https://bbp.epfl.ch/bbp/inference-rules/views/aggreg-es/rule_view"
          },
          {
            name  = "SPARQL_RULE_VIEW",
            value = "https://bbp.epfl.ch/bbp/inference-rules/views/aggreg-sp/rule_view"
          },
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
      file_system_id     = aws_efs_file_system.kg_inference_api_efs_instance.id
      root_directory     = "/etc/nginx"
      transit_encryption = "ENABLED"
    }
  }
}

# Service
resource "aws_ecs_service" "kg_inference_api_service" {
  name                 = "kg-inference-api-service"
  cluster              = aws_ecs_cluster.kg_inference_api_cluster.id
  task_definition      = aws_ecs_task_definition.kg_inference_api_task_definition.arn
  desired_count        = 1
  force_new_deployment = true
  launch_type          = "FARGATE"


  # Load Balancer configuration
  load_balancer {
    target_group_arn = aws_lb_target_group.kg_inference_api_tg.arn
    container_name   = "nginx-reverse-proxy-container"
    container_port   = 80
  }

  network_configuration {
    security_groups  = [aws_security_group.kg_inference_api_sec_group.id]
    subnets          = [aws_subnet.kg_inference_api.id]
    assign_public_ip = false
  }
}