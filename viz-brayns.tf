resource "aws_cloudwatch_log_group" "viz_brayns" {
  name              = "viz_brayns"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "viz_brayns"
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_cluster" "viz_ecs_cluster" {
  name = "viz_ecs_cluster"

  tags = {
    Application = "viz"
    SBO_Billing = "viz"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "viz_brayns_ecs_task" {
  name        = "viz_brayns_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for Brayns renderer service"

  tags = {
    Name        = "viz_brayns_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_brayns_allow_port_8200" {
  security_group_id = aws_security_group.viz_brayns_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8200
  to_port     = 8200
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8200 http / websocket"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_brayns_allow_outgoing" {
  security_group_id = aws_security_group.viz_brayns_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_task_definition" "viz_brayns_ecs_definition" {
  family       = "viz_brayns_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "viz_brayns"
      essential   = true
      image       = var.viz_brayns_docker_image_url
      name        = "viz_brayns"
      repositoryCredentials = {
        credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8200
          containerPort = 8200
          protocol      = "tcp"
        }
      ]
      entrypoint = [
        "/opt/view/bin/braynsService",
        "--uri",
        "0.0.0.0:8200",
        "--log-level",
        "info",
        "--plugin",
        "braynsCircuitExplorer",
        "--plugin",
        "braynsAtlasExplorer"
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "/opt/view/bin/braynsHealthcheck localhost:8200 || exit 1"]
        interval    = 300
        timeout     = 60
        startPeriod = 300
        retries     = 10
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.viz_brayns_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "viz_brayns"
        }
      }
    }
  ])

  memory                   = 2048
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.viz_brayns_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.viz_brayns_ecs_task_role.arn

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_service" "viz_brayns_ecs_service" {
  name                              = "viz_brayns_ecs_service"
  cluster                           = aws_ecs_cluster.viz_ecs_cluster.id
  launch_type                       = "FARGATE"
  task_definition                   = aws_ecs_task_definition.viz_brayns_ecs_definition.arn
  desired_count                     = var.viz_brayns_ecs_number_of_containers
  health_check_grace_period_seconds = var.viz_brayns_ecs_lb_grace_period
  enable_execute_command            = true

  network_configuration {
    security_groups  = [aws_security_group.viz_brayns_ecs_task.id]
    subnets          = [aws_subnet.viz.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.viz_brayns,
    aws_iam_role.viz_brayns_ecs_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.viz_brayns.arn
    container_name   = "viz_brayns"
    container_port   = 8200
  }
  force_new_deployment = true
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role" "viz_brayns_ecs_task_execution_role" {
  name = "viz_brayns-ecsTaskExecutionRole"

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

resource "aws_iam_role_policy_attachment" "viz_brayns_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.viz_brayns_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "viz_brayns_ecs_task_role" {
  name               = "viz_brayns-ecsTaskRole"
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

resource "aws_iam_role_policy_attachment" "viz_brayns_ecs_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.viz_brayns_ecs_task_execution_role.name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy" "ecs_exec_policy" {
  name = "ecs_exec_policy"
  role = aws_iam_role.viz_brayns_ecs_task_role.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" : "*"
      }
    ]
  })
}
