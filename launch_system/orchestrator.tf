resource "aws_cloudwatch_log_group" "orchestrator" {
  # TODO check if the logs can be encrypted
  name_prefix       = "launch_system_orchestrator"
  skip_destroy      = false
  retention_in_days = 14

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Name = "launch_system_orchestrator" })
}

resource "aws_ecs_cluster" "orchestrator" {
  name = "launch_system_orchestrator"

  tags = merge(var.tags, { Name = "launch_system_orchestrator" })


  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "orchestrator" {
  name_prefix = "launch_system_orchestrator"
  vpc_id      = var.vpc_id
  description = "Sec group for launch system orchestrator"

  tags = merge(var.tags, { Name = "launch_system_orchestrator" })
}

resource "aws_vpc_security_group_egress_rule" "orchestrator_allow_outgoing_tcp" {
  security_group_id = aws_security_group.orchestrator.id
  # TODO limit to what is needed
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all TCP"
}

resource "aws_vpc_security_group_egress_rule" "orchestrator_allow_outgoing_udp" {
  security_group_id = aws_security_group.orchestrator.id
  # TODO limit to what is needed
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow all UDP"
}

resource "aws_ecs_task_definition" "orchestrator" {
  family       = "launch_system_orchestrator_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      name = "main"

      cpu    = var.orchestrator_task_size.cpu
      memory = var.orchestrator_task_size.memory

      image = var.orchestrator_image_url

      essential = true

      readonlyRootFilesystem = true

      mountPoints = [
        {
          sourceVolume  = "tmp"
          containerPath = "/tmp"
          readOnly      = false
        }
      ]

      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: add a proper health check.
        interval    = 60
        timeout     = 5
        startPeriod = 30
        retries     = 3
      }

      environment = [
        {
          name  = "WORKER_API_URL"
          value = var.launch_system_api_url
        },
        {
          name  = "WORKER_AWS_REGION"
          value = var.aws_region
        },
        {
          name  = "WORKER_AWS_ACCOUNT_ID"
          value = var.account_id
        },
        {
          name  = "WORKER_AWS_ECS_CLUSTER_NAME"
          value = aws_ecs_cluster.executor.name
        },
        {
          name  = "WORKER_AWS_ECS_TASK_FAMILY"
          value = aws_ecs_task_definition.default_executor.family
        },
        {
          name = "WORKER_AWS_ECS_TASK_FAMILIES"
          value = jsonencode(
            {
              "openbraininstitute-partners/inait" : aws_ecs_task_definition.inait_executor.family,
            }
          )
        },
        {
          name  = "WORKER_AWS_ECS_TASK_SUBNETS"
          value = jsonencode([var.untrusted_a_subnet_id, var.untrusted_b_subnet_id])
        },
        {
          name  = "WORKER_AWS_ECS_TASK_SECURITY_GROUPS"
          value = jsonencode([aws_security_group.executor.id])
        },
        {
          name  = "REDIS_HOST"
          value = aws_elasticache_cluster.redis.cache_nodes[0].address
        },
        {
          name  = "REDIS_PORT"
          value = tostring(aws_elasticache_cluster.redis.port)
        },
        {
          name  = "REDIS_URL" # deprecated, use REDIS_HOST and REDIS_PORT
          value = "redis://${aws_elasticache_cluster.redis.cache_nodes[0].address}:${aws_elasticache_cluster.redis.port}/0"
        },
        {
          name  = "QUEUES"
          value = join(" ", var.queues)
        },
        {
          name  = "NUM_WORKERS"
          value = tostring(var.orchestrator_num_workers)
        },
        {
          name  = "VENDOR"
          value = "aws"
        },
        {
          name  = "CLUSTER_TASK_MAXIMUM_RUNTIME"
          value = var.cluster_task_maximum_runtime
        },
        {
          name  = "AZ_REGION"
          value = var.az_region
        },
        {
          name  = "AZ_INSTANCE_TYPES"
          value = var.az_instance_types
        },
        {
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
        },
        {
          name  = "LAUNCH_SYSTEM_API_URL"
          value = var.launch_system_api_url
        },
        {
          name  = "LOCAL_STORE_PREFIX"
          value = var.local_store_prefix
        },
      ]

      secrets = [
        {
          name      = "AZURE_CLIENT_ID"
          valueFrom = "${var.secrets_arn}:AZURE_CLIENT_ID::"
        },
        {
          name      = "AZURE_CLIENT_SECRET"
          valueFrom = "${var.secrets_arn}:AZURE_CLIENT_SECRET::"
        },
        {
          name      = "AZURE_TENANT_ID"
          valueFrom = "${var.secrets_arn}:AZURE_TENANT_ID::"
        },
        {
          name      = "AZ_SUBSCRIPTION_ID"
          valueFrom = "${var.secrets_arn}:AZ_SUBSCRIPTION_ID::"
        },
        {
          name      = "AZ_BATCH_ACCOUNT_NAME"
          valueFrom = "${var.secrets_arn}:AZ_BATCH_ACCOUNT_NAME::"
        },
        {
          name      = "AZ_BATCH_POOL_NAME"
          valueFrom = "${var.secrets_arn}:AZ_BATCH_POOL_NAME::"
        },
        {
          name      = "AZ_UPLOAD_BLOB_SAS_URL"
          valueFrom = "${var.secrets_arn}:AZ_UPLOAD_BLOB_SAS_URL::"
        },
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.orchestrator.name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "launch_system_orchestrator"
        }
      }
    }
  ])

  cpu    = var.orchestrator_task_size.cpu
  memory = var.orchestrator_task_size.memory

  requires_compatibilities = ["FARGATE"]

  volume {
    name = "tmp"
  }

  execution_role_arn = aws_iam_role.orchestrator_execution.arn
  task_role_arn      = aws_iam_role.orchestrator_task.arn

  depends_on = [
    aws_cloudwatch_log_group.orchestrator,
  ]
}

resource "aws_ecs_service" "orchestrator" {
  name            = "launch_system_orchestrator"
  cluster         = aws_ecs_cluster.orchestrator.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.orchestrator.arn

  network_configuration {
    security_groups = [aws_security_group.orchestrator.id]
    subnets = [
      var.trusted_a_subnet_id,
      var.trusted_b_subnet_id,
    ]
    assign_public_ip = false
  }

  depends_on = [
    aws_iam_role.orchestrator_execution,
  ]

  force_new_deployment = true
  desired_count        = 1

  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "orchestrator_execution" {
  name_prefix = "launch_system_orchestrator"

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

resource "aws_iam_role_policy_attachment" "orchestrator_execution" {
  role       = aws_iam_role.orchestrator_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "orchestrator_task" {
  name_prefix = "launch_system_orchestrator"

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

resource "aws_iam_policy" "orchestrator_logs_access" {
  name_prefix = "launch_system_orchestrator"
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


resource "aws_iam_policy" "orchestrator_ecs_run_task" {
  name_prefix = "launch_system_orchestrator"
  description = "Allows orchestrator to run ECS tasks in the executor cluster"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask",
        ]
        Resource = [
          aws_ecs_task_definition.default_executor.arn,
          aws_ecs_task_definition.inait_executor.arn,
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:ListTasks",
        ]
        Resource = [
          "${aws_ecs_cluster.executor.arn}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ecs:StopTask",
          "ecs:TagResource",
          "ecs:DescribeTasks",
        ]
        Resource = [
          "arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_cluster.executor.name}/*",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole",
        ]
        Resource = [
          aws_iam_role.executor_execution.arn,
          aws_iam_role.executor_task.arn,
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "orchestrator_ecs_run_task" {
  role       = aws_iam_role.orchestrator_task.name
  policy_arn = aws_iam_policy.orchestrator_ecs_run_task.arn
}

resource "aws_iam_role_policy_attachment" "orchestrator_secrets_access" {
  role       = aws_iam_role.orchestrator_execution.name
  policy_arn = aws_iam_policy.secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "orchestrator_logs_access" {
  role       = aws_iam_role.orchestrator_execution.name
  policy_arn = aws_iam_policy.orchestrator_logs_access.arn
}
