################################################################################
# Resource definitions
################################################################################
resource "aws_cloudwatch_log_group" "embedder" {
  name              = "embedder"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "embedder"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_ecs_cluster" "ml_ecs_cluster" {
  name = "machinelearning_ecs_cluster"

  tags = {
    Application = "machinelearning"
    SBO_Billing = "machinelearning"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "embedder_ecs_task" {
  name        = "embedder_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for embedder webapp"

  tags = {
    Name        = "embedder_secgroup"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_ingress_rule" "embedder_allow_port_3000" {
  security_group_id = aws_security_group.embedder_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 3000
  to_port     = 3000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 3000 http"

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_egress_rule" "embedder_allow_outgoing" {
  security_group_id = aws_security_group.embedder_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow everything"

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_ecs_task_definition" "embedder_ecs_definition" {
  count = var.embedder_ecs_number_of_containers > 0 ? 1 : 0

  family       = "embedder_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 1024
      cpu         = 512
      networkMode = "awsvpc"
      family      = "embedder"
      essential   = true
      image       = var.embedder_docker_image_url
      name        = "embedder"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 3000
          containerPort = 3000
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:3000/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.embedder_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "embedder"
        }
      }
    }
  ])

  memory                   = 1024
  cpu                      = 512
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_embedder_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_embedder_task_role[0].arn

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_ecs_service" "embedder_ecs_service" {
  count = var.embedder_ecs_number_of_containers > 0 ? 1 : 0

  name            = "embedder_ecs_service"
  cluster         = aws_ecs_cluster.ml_ecs_cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.embedder_ecs_definition[0].arn
  desired_count   = var.embedder_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  network_configuration {
    security_groups  = [aws_security_group.embedder_ecs_task.id]
    subnets          = [aws_subnet.machinelearning.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.embedder,
    aws_iam_role.ecs_embedder_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.embedder.arn
    container_name   = "embedder"
    container_port   = 3000
  }
  # force redeployment on each tf apply
  force_new_deployment = true
  #triggers = {
  #  redeployment = timestamp()
  #}
  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_iam_role" "ecs_embedder_task_execution_role" {
  count = var.embedder_ecs_number_of_containers > 0 ? 1 : 0
  name  = "embedder-ecsTaskExecutionRole"

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
    SBO_Billing = "machinelearning"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_embedder_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_embedder_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.embedder_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_embedder_task_role" {
  count = var.embedder_ecs_number_of_containers > 0 ? 1 : 0
  name  = "embedder-ecsTaskRole"

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
    SBO_Billing = "machinelearning"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_embedder_task_role_dockerhub_policy_attachment" {
  count      = var.embedder_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_embedder_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}
