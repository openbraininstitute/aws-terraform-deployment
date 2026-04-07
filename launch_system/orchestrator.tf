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
          name  = "ORCHESTRATOR_API_URL"
          value = var.launch_system_api_url
        },
        {
          name  = "ORCHESTRATOR_CLUSTER_TASK_MAXIMUM_RUNTIME"
          value = var.cluster_task_maximum_runtime
        },
        {
          name  = "ORCHESTRATOR_DEPLOYMENT"
          value = var.deployment_env
        },
        {
          name  = "ORCHESTRATOR_ENTITYCORE_URL"
          value = var.entitycore_url
        },
        {
          name  = "ORCHESTRATOR_LOCAL_STORE_PREFIX"
          value = var.local_store_prefix
        },
        {
          name  = "ORCHESTRATOR_SIMULATION_LAUNCH_COMMAND"
          value = var.simulation_launch_command
        },
        {
          name  = "ORCHESTRATOR_CODEARTIFACT_CONFIG"
          value = jsonencode(var.codeartifact_config)
        },
        {
          name  = "ORCHESTRATOR_COMPUTE_CELL_DEFINITIONS"
          value = local.compute_cell_definitions_tmpl
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
      ]

      # ORCHESTRATOR_SECRETS
      # --------------------
      # This must be the ARN of an AWS Secrets Manager secret containing a JSON object.
      #
      # The JSON keys must match the $${SECRET:<KEY>} placeholders defined in
      # launch_system/compute_cell_definitions.tf under `compute_cell_definitions`.
      #
      # These secrets are interpolated into ORCHESTRATOR_COMPUTE_CELL_DEFINITIONS
      # at runtime.
      #
      # Example expected secret JSON structure:
      #
      # {
      #   "AZ_SUBSCRIPTION_ID": "...",
      #   "AZ_TENANT_ID": "...",
      #   "AZ_CLIENT_ID": "...",
      #   "AZ_CLIENT_SECRET": "...",
      #   "AZ_BATCH_ACCOUNT_URL": "...",
      #   "AZ_UPLOAD_BLOB_SAS_URL": "..."
      # }
      #
      # See launch_system/compute_cell_definitions.tf for the full list of
      # required SECRET placeholders.
      #
      secrets = [
        {
          name      = "ORCHESTRATOR_SECRETS"
          valueFrom = var.secrets_arn
        },
        {
          name      = "CAPABILITY_ENV_SECRETS"
          valueFrom = var.launch_system_capability_secrets_arn
        }
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
      aws_subnet.trusted_a.id,
      aws_subnet.trusted_b.id,
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
          aws_iam_role.default_executor_execution.arn,
          aws_iam_role.inait_executor_execution.arn,
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
  policy_arn = aws_iam_policy.full_secrets_access.arn
}

resource "aws_iam_role_policy_attachment" "orchestrator_logs_access" {
  role       = aws_iam_role.orchestrator_execution.name
  policy_arn = aws_iam_policy.orchestrator_logs_access.arn
}
