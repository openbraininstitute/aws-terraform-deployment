locals {
  blazegraph_app_log_group_name = "blazegraph_app"
}

# Blazegraph needs some storage for data
resource "aws_efs_file_system" "blazegraph" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-blazegraph"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "sbp-poc-blazegraph"
    SBO_Billing = "nexus"
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.blazegraph.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_blazegraph" {
  file_system_id  = aws_efs_file_system.blazegraph.id
  subnet_id       = var.subnet_id
  security_groups = [var.subnet_security_group_id]
}

resource "aws_cloudwatch_log_group" "blazegraph_app" {
  name              = local.blazegraph_app_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "blazegraph"
    SBO_Billing = "nexus"
  }
}

resource "aws_ecs_task_definition" "blazegraph_ecs_definition" {
  count        = var.blazegraph_ecs_number_of_containers > 0 ? 1 : 0
  family       = "blazegraph_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 6144
      networkMode = "awsvpc"
      cpu         = 1024
      family      = "blazegraph"
      portMappings = [
        {
          hostPort      = 9999
          containerPort = 9999
          protocol      = "tcp"
        }
      ]
      essential = true
      name      = "blazegraph"
      image     = var.blazegraph_docker_image_url
      environment = [
        {
          name  = "JAVA_OPTS"
          value = " -Dlog4j.configuration=/var/lib/blazegraph/log4j/log4j.properties -Djava.awt.headless=true -Djava.awt.headless=true -XX:MaxDirectMemorySize=600m -Xms3g -Xmx3g -XX:+UseG1GC "
        },
        {
          name  = "JETTY_START_TIMEOUT"
          value = "120"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = local.blazegraph_app_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "blazegraph_app"
        }
      }
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      mountPoints = [
        {
          sourceVolume  = "efs-blazegraph-data"
          containerPath = "/var/lib/blazegraph/data"
          readOnly      = false
        },
        {
          sourceVolume  = "efs-blazegraph-log4j"
          containerPath = "/var/lib/blazegraph/log4j"
          readOnly      = false
        }
      ]
    }
  ])

  cpu                      = 1024
  memory                   = 6144
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_blazegraph_task_execution_role[0].arn
  #task_role_arn            = aws_iam_role.ecs_blazegraph_task_role[0].arn

  volume {
    name = "efs-blazegraph-data"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      root_directory     = var.efs_blazegraph_data_dir
      transit_encryption = "ENABLED"
    }
  }
  volume {
    name = "efs-blazegraph-log4j"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.blazegraph.id
      root_directory     = var.efs_blazegraph_log4j_dir
      transit_encryption = "ENABLED"
    }
  }
  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_ecs_service" "blazegraph_ecs_service" {
  count = var.blazegraph_ecs_number_of_containers > 0 ? 1 : 0

  name        = "blazegraph_ecs_service"
  cluster     = var.ecs_cluster_arn
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.blazegraph_ecs_definition[0].arn
  desired_count   = var.blazegraph_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = aws_lb_target_group.blazegraph.arn
    container_name   = "blazegraph"
    container_port   = 9999
  }
  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.blazegraph_app
    #aws_iam_role.ecs_blazegraph_task_execution_role, # wrong?

  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  #triggers = {
  #  redeployment = timestamp()
  #}
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_iam_role" "ecs_blazegraph_task_execution_role" {
  count = var.blazegraph_ecs_number_of_containers > 0 ? 1 : 0
  name  = "blazegraph-ecsTaskExecutionRole"

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
    SBO_Billing = "nexus"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_blazegraph_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_blazegraph_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  count      = var.blazegraph_ecs_number_of_containers > 0 ? 1 : 0
}
