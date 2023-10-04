resource "aws_cloudwatch_log_group" "viz_bcsb" {
  name              = "viz_bcsb"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "viz_bcsb"
    SBO_Billing = "viz"
  }
}

# TODO make more strict
resource "aws_security_group" "viz_bcsb_ecs_task" {
  name        = "viz_bcsb_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for BCSB service"

  tags = {
    Name        = "viz_bcsb_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_bcsb_allow_port_8000" {
  security_group_id = aws_security_group.viz_bcsb_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8000 http / websocket"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_bcsb_allow_outgoing" {
  security_group_id = aws_security_group.viz_bcsb_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_task_definition" "viz_bcsb_ecs_definition" {
  count = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0

  family       = "viz_bcsb_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "viz_bcsb"
      essential   = true
      image       = var.viz_bcsb_docker_image_url
      name        = "viz_bcsb"
      repositoryCredentials = {
        credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      entrypoint = [
        "/opt/view/bin/bcsb",
        "--host",
        "0.0.0.0",
        "--port",
        "8000",
        "--log_level",
        "INFO"
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "/opt/view/bin/bcsb_healthcheck ws://localhost:8000 || exit 1"]
        interval    = 300
        timeout     = 60
        startPeriod = 300
        retries     = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.viz_bcsb_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "viz_bcsb"
        }
      }
    }
  ])

  memory                   = 2048
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.viz_bcsb_ecs_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.viz_bcsb_ecs_task_role[0].arn

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_service" "viz_bcsb_ecs_service" {
  count = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0

  name                              = "viz_bcsb_ecs_service"
  cluster                           = aws_ecs_cluster.viz_ecs_cluster.id
  launch_type                       = "FARGATE"
  task_definition                   = aws_ecs_task_definition.viz_bcsb_ecs_definition[0].arn
  desired_count                     = var.viz_bcsb_ecs_number_of_containers
  health_check_grace_period_seconds = var.viz_bcsb_ecs_lb_grace_period

  network_configuration {
    security_groups  = [aws_security_group.viz_bcsb_ecs_task.id]
    subnets          = [aws_subnet.viz.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.viz_bcsb,
    aws_iam_role.viz_bcsb_ecs_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.viz_bcsb.arn
    container_name   = "viz_bcsb"
    container_port   = 8000
  }
  force_new_deployment = true
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role" "viz_bcsb_ecs_task_execution_role" {
  count = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0
  name  = "viz_bcsb-ecsTaskExecutionRole"

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
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_bcsb_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.viz_bcsb_ecs_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "viz_bcsb_ecs_task_role" {
  count = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0
  name  = "viz_bcsb-ecsTaskRole"

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
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_bcsb_ecs_task_role_dockerhub_policy_attachment" {
  count      = var.viz_bcsb_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.viz_bcsb_ecs_task_execution_role[0].name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}
