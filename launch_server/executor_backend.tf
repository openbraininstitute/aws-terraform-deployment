locals {
  executor_cpu    = 1024
  executor_memory = 2048
}

resource "aws_cloudwatch_log_group" "executor_launch_ecs_task_logs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "launch"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "executor_launch"
  }
}

resource "aws_ecs_cluster" "executor_launch" {
  name = "executor_launch_ecs_cluster"

  tags = {
    Name = "executor_launch"
  }

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make outgoing more strict, allow incoming if needed
resource "aws_security_group" "executor_launch_ecs_task" {
  name_prefix = "executor_launch"
  vpc_id      = var.vpc_id
  description = "Sec group for executor_launch service"

  tags = {
    Name = "executor_launch_secgroup"
  }
}

resource "aws_vpc_security_group_egress_rule" "executor_launch_allow_outgoing_tcp" {
  security_group_id = aws_security_group.executor_launch_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "executor_launch_allow_outgoing_udp" {
  security_group_id = aws_security_group.executor_launch_ecs_task.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "executor_launch_ecs_definition" {
  family       = "executor_launch_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name   = "executor_launch"
      family = "launch"

      cpu    = local.executor_cpu
      memory = local.executor_memory

      networkMode = "awsvpc"

      image = var.executor_image_url

      essential = true

      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: add a proper health check once there is something to check the health of.
        interval    = 60
        timeout     = 5
        startPeriod = 30
        retries     = 3
      }



      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.executor_launch_ecs_task_logs.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "executor_launch"
        }
      }
    }
  ])

  cpu    = local.cpu
  memory = local.memory

  requires_compatibilities = ["FARGATE"]

  execution_role_arn = aws_iam_role.ecs_launch_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_launch_task_role.arn

  depends_on = [
    aws_cloudwatch_log_group.executor_launch_ecs_task_logs,
  ]
}

# resource "aws_ecs_service" "executor_launch_ecs_service" {
#   name            = "executor_launch_ecs_service"
#   cluster         = aws_ecs_cluster.executor_launch.id
#   launch_type     = "FARGATE"
#   task_definition = aws_ecs_task_definition.executor_launch_ecs_definition.arn
#
#   network_configuration {
#     security_groups = [aws_security_group.executor_launch_ecs_task.id]
#     subnets = [aws_subnet.launch_ecs_a.id,
#       aws_subnet.launch_ecs_b.id,
#     ]
#     assign_public_ip = false
#   }
#
#   depends_on = [
#     aws_iam_role.ecs_launch_task_execution_role,
#   ]
#
#   force_new_deployment = true
#   desired_count        = 1
#
#   propagate_tags = "SERVICE"
# }
