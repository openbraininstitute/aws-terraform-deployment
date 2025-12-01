locals {
  # Shared task definition configuration
  executor_base_config = {
    network_mode             = "awsvpc"
    cpu                      = var.executor_task_size.cpu
    memory                   = var.executor_task_size.memory
    requires_compatibilities = ["FARGATE"]
    execution_role_arn       = aws_iam_role.executor_execution.arn
    task_role_arn            = aws_iam_role.executor_task.arn
  }

  # Shared container base configuration
  executor_container_base = {
    name               = "main"
    cpu                = var.executor_task_size.cpu
    memory             = var.executor_task_size.memory
    essential          = true
    initProcessEnabled = true # prevent zombies

    mountPoints = [
      {
        containerPath = "/data/aws_s3_internal/public"
        sourceVolume  = "public-internal-data"
      },
      {
        containerPath = "/data/aws_s3_open"
        sourceVolume  = "public-open-data"
      }
    ]

    healthcheck = {
      command     = ["CMD-SHELL", "exit 0"]
      interval    = 60
      timeout     = 5
      startPeriod = 30
      retries     = 3
    }

    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group        = aws_cloudwatch_log_group.executor.name
        awslogs-region       = var.aws_region
        awslogs-create-group = "true"
      }
    }
  }

  # Shared volumes configuration
  executor_volumes = [
    {
      name = "public-internal-data"
      efs_volume_configuration = {
        file_system_id     = var.public_launch_data_efs_id
        transit_encryption = "ENABLED"
        authorization_config = {
          access_point_id = var.internal_public_data_access_point_id
          iam             = "ENABLED"
        }
      }
    },
    {
      name = "public-open-data"
      efs_volume_configuration = {
        file_system_id     = var.public_launch_data_efs_id
        transit_encryption = "ENABLED"
        authorization_config = {
          access_point_id = var.open_public_data_access_point_id
          iam             = "ENABLED"
        }
      }
    }
  ]
}

resource "aws_cloudwatch_log_group" "executor" {
  # TODO check if the logs can be encrypted
  name_prefix       = "launch_system_executor"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Name = "launch_system_executor" })
}

resource "aws_ecs_cluster" "executor" {
  name = "launch_system_executor"

  tags = merge(var.tags, { Name = "launch_system_executor" })

  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make outgoing more strict, allow incoming if needed
resource "aws_security_group" "executor" {
  name_prefix = "launch_system_executor"
  vpc_id      = var.vpc_id
  description = "Security group for executor service"

  tags = merge(var.tags, { Name = "launch_system_executor" })
}

resource "aws_vpc_security_group_egress_rule" "executor_allow_outgoing_tcp" {
  security_group_id = aws_security_group.executor.id
  # TODO limit to what is needed
  #  * NFS: port 2049 to the security group of the shared filesystem
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "executor_allow_outgoing_udp" {
  security_group_id = aws_security_group.executor.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "default_executor" {
  family                   = "launch_system_default_executor_task_family"
  network_mode             = local.executor_base_config.network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = local.executor_base_config.requires_compatibilities
  execution_role_arn       = local.executor_base_config.execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.default_executor_image_url
      environment = [
        {
          name  = "DEPLOYMENT"
          value = var.deployment_env
        },
        {
          name  = "EXECUTOR_NAME"
          value = "default"
        },
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_default_executor"
        })
      })
    })
  ])

  dynamic "volume" {
    for_each = local.executor_volumes
    content {
      name = volume.value.name
      efs_volume_configuration {
        file_system_id     = volume.value.efs_volume_configuration.file_system_id
        transit_encryption = volume.value.efs_volume_configuration.transit_encryption
        authorization_config {
          access_point_id = volume.value.efs_volume_configuration.authorization_config.access_point_id
          iam             = volume.value.efs_volume_configuration.authorization_config.iam
        }
      }
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}
resource "aws_ecs_task_definition" "inait_executor" {
  family                   = "launch_system_inait_executor_task_family"
  network_mode             = local.executor_base_config.network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = local.executor_base_config.requires_compatibilities
  execution_role_arn       = local.executor_base_config.execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.default_executor_image_url
      environment = [
        {
          name  = "DEPLOYMENT"
          value = var.deployment_env
        },
        {
          name  = "EXECUTOR_NAME"
          value = "inait"
        },
      ]
      secrets = [
        {
          name      = "GITHUB_DEPLOY_KEY_B64"
          valueFrom = "${var.secrets_arn}:GITHUB_DEPLOY_KEY_B64__inait::"
        },
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_inait_executor"
        })
      })
    })
  ])

  dynamic "volume" {
    for_each = local.executor_volumes
    content {
      name = volume.value.name
      efs_volume_configuration {
        file_system_id     = volume.value.efs_volume_configuration.file_system_id
        transit_encryption = volume.value.efs_volume_configuration.transit_encryption
        authorization_config {
          access_point_id = volume.value.efs_volume_configuration.authorization_config.access_point_id
          iam             = volume.value.efs_volume_configuration.authorization_config.iam
        }
      }
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}

# aws_ecs_service isn't defined because the ECS tasks are started dynamically by the orchestrator,
# with the proper cluster, taskDefinition, launchType, and networkConfiguration

# resource "aws_ecs_service" "default_executor" {
#   name            = "launch_system_default_executor"
#   cluster         = aws_ecs_cluster.executor.id
#   launch_type     = "FARGATE"
#   task_definition = aws_ecs_task_definition.default_executor.arn
#
#   network_configuration {
#     security_groups = [aws_security_group.executor.id]
#     subnets = [
#       aws_subnet.untrusted_a.id,
#       aws_subnet.untrusted_b.id,
#     ]
#     assign_public_ip = false
#   }
#
#   depends_on = [
#     aws_iam_role.executor_execution,
#   ]
#
#   force_new_deployment = true
#   desired_count        = 1
#
#   propagate_tags = "SERVICE"
# }

resource "aws_iam_role" "executor_execution" {
  name_prefix = "launch_system_executor"

  assume_role_policy = <<-EOT
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
  EOT
}

resource "aws_iam_role_policy_attachment" "executor_execution" {
  role       = aws_iam_role.executor_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "executor_task" {
  name_prefix = "launch_system_executor"

  assume_role_policy = <<-EOT
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
  EOT
}

resource "aws_iam_policy" "executor_logs_access" {
  name_prefix = "launch_system_executor"
  description = "Allows ECS tasks to create log streams and log groups in CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "executor_secrets_access" {
  role       = aws_iam_role.executor_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "executor_logs_access" {
  role       = aws_iam_role.executor_execution.name
  policy_arn = aws_iam_policy.executor_logs_access.arn
}
