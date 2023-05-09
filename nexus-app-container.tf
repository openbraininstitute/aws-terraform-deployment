# Blazegraph needs some storage for data
resource "aws_efs_file_system" "nexus_app_config" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-nexus-app-config"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = true
  tags = {
    Name        = "sbp-poc-nexus-app-config"
    SBO_Billing = "nexus_app"
  }
}

resource "aws_efs_backup_policy" "nexus_backup_policy" {
  file_system_id = aws_efs_file_system.nexus_app_config.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_nexus_app" {
  file_system_id  = aws_efs_file_system.nexus_app_config.id
  subnet_id       = aws_subnet.nexus_app.id
  security_groups = [aws_security_group.nexus_app_efs.id]
}

# TODO make more strict
resource "aws_security_group" "nexus_app_efs" {
  name   = "nexus_app_efs"
  vpc_id = aws_vpc.sbo_poc.id

  description = "Nexus app EFS filesystem"

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow ingress within vpc"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [aws_vpc.sbo_poc.cidr_block]
    description = "allow egress within vpc"
  }
  tags = {
    Application = "nexus_app"
    SBO_Billing = "nexus_app"
  }
}

resource "aws_cloudwatch_log_group" "nexus_app" {
  # TODO check if the logs can be encrypted
  name              = var.nexus_delta_app_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "nexus_app"
    SBO_Billing = "nexus_app"
  }
}

resource "aws_ecs_cluster" "nexus_app" {
  name = "nexus_app_ecs_cluster"

  tags = {
    Application = "nexus_app"
    SBO_Billing = "nexus_app"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "nexus_app_ecs_task" {
  name        = "nexus_app_ecs_task"
  vpc_id      = aws_vpc.sbo_poc.id
  description = "Sec group for SBO nexus app"

  tags = {
    Name        = "nexus_app_secgroup"
    SBO_Billing = "nexus_app"
  }
}

resource "aws_vpc_security_group_ingress_rule" "nexus_app_allow_port_8000" {
  security_group_id = aws_security_group.nexus_app_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = aws_vpc.sbo_poc.cidr_block
  description = "Allow port 8000 http"
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_vpc_security_group_egress_rule" "nexus_app_allow_outgoing" {
  security_group_id = aws_security_group.nexus_app_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 0
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = aws_vpc.sbo_poc.cidr_block
  description = "Allow everything"
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_ecs_task_definition" "nexus_app_ecs_definition" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0

  family       = "nexus_app_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 1024
      cpu         = 512
      command     = ["/bin/bash", "-c", "/opt/docker/bin/delta-app"]
      networkMode = "awsvpc"
      family      = "sbonexusapp"
      essential   = true
      image       = var.nexus_delta_docker_image_url
      name        = "nexus_app"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.nexus_delta_app_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "nexus_app"
        }
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_nexus_app_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_nexus_app_task_role[0].arn

  volume {
    name = "efs-nexus-app-config"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.nexus_app_config.id
      root_directory     = "/opt/appconf"
      transit_encryption = "ENABLED"
    }
  }

  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_ecs_service" "nexus_app_ecs_service" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0

  name            = "nexus_app_ecs_service"
  cluster         = aws_ecs_cluster.nexus_app.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_app_ecs_definition[0].arn
  desired_count   = var.nexus_app_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.nexus_app.arn
    container_name   = "nexus_app"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.nexus_app_ecs_task.id]
    subnets          = [aws_subnet.nexus_app.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_app,
    aws_iam_role.ecs_nexus_app_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [task_definition, desired_count]
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_iam_role" "ecs_nexus_app_task_execution_role" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_app-ecsTaskExecutionRole"

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
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_nexus_app_task_role" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  name  = "nexus_app-ecsTaskRole"

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
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_task_role_dockerhub_policy_attachment" {
  count      = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_nexus_app_secrets_access_policy_attachment" {
  count      = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_nexus_app_task_execution_role[0].name
  policy_arn = aws_iam_policy.sbo_nexus_app_secrets_access.arn
}
