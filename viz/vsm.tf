resource "aws_cloudwatch_log_group" "viz_vsm" {
  name              = "viz_vsm"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "viz_vsm"
    SBO_Billing = "viz"
  }
}

# TODO make more strict
resource "aws_security_group" "viz_vsm_ecs_task" {
  name        = "viz_vsm_ecs_task"
  vpc_id      = data.aws_vpc.selected.id
  description = "Sec group for vsm service"
  tags = {
    Name        = "viz_vsm_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_vsm_allow_port_4444" {
  security_group_id = aws_security_group.viz_vsm_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 4444
  to_port     = 4444
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  description = "Allow port 4444 http"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_vsm_allow_outgoing" {
  security_group_id = aws_security_group.viz_vsm_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_task_definition" "viz_vsm" {
  family       = "viz_vsm_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "viz_vsm"
      essential   = true
      image       = var.viz_vsm_docker_image_url
      name        = "viz_vsm"
      repositoryCredentials = {
        credentialsParameter = data.aws_secretsmanager_secret.dockerhub_creds.arn
      }
      portMappings = [
        {
          hostPort      = 4444
          containerPort = 4444
          protocol      = "tcp"
        }
      ]
      entrypoint = ["vsm_master"]
      command = [
        "--address",
        "0.0.0.0",
        "--port",
        "4444"
      ]
      environment = [
        {
          name  = "VSM_LOG_LEVEL"
          value = "DEBUG"
        },
        {
          name  = "VSM_DB_NAME"
          value = var.viz_postgresql_database_name
        },
        {
          name  = "VSM_DB_USERNAME"
          value = var.viz_postgresql_database_username
        },
        {
          name  = "VSM_RECREATE_DB"
          value = "1"
        },
        {
          name  = "VSM_JOB_ALLOCATOR"
          value = "AWS"
        },
        {
          name  = "VSM_JOB_DURATION_SECONDS"
          value = "28800"
        },
        {
          name  = "VSM_JOB_CLEANUP_PERIOD_SECONDS"
          value = "10"
        },
        {
          name  = "VSM_USE_KEYCLOAK"
          value = var.viz_enable_sandbox ? "0" : "1"
        },
        {
          name  = "VSM_KEYCLOAK_URL"
          value = "https://openbluebrain.com/auth/realms/SBO/protocol/openid-connect/userinfo"
        },
        {
          name  = "VSM_KEYCLOAK_HOST"
          value = "openbluebrain.com"
        },
        {
          name  = "VSM_BRAYNS_TASK_DEFINITION"
          value = aws_ecs_task_definition.viz_brayns.arn
        },
        {
          name  = "VSM_BRAYNS_TASK_SECURITY_GROUPS"
          value = aws_security_group.viz_ec2.id
        },
        {
          name  = "VSM_BRAYNS_TASK_SUBNETS"
          value = aws_subnet.viz.id
        },
        {
          name  = "VSM_BRAYNS_TASK_CLUSTER"
          value = aws_ecs_cluster.viz.name
        },
        {
          name  = "VSM_BRAYNS_TASK_CAPACITY_PROVIDER"
          value = aws_ecs_capacity_provider.viz.name
        },
        {
          name  = "VSM_BUCKET_NAME"
          value = "sbo-cell-svc-perf-test"
        },
        {
          name  = "VSM_BUCKET_MOUNT_PATH"
          value = "/sbo/data/project"
        },
        {
          name  = "PYTHONUNBUFFERED"
          value = "TRUE"
        }
      ]
      mountPoints = []
      volumesFrom = []
      healthcheck = {
        interval = 30
        retries  = 3
        timeout  = 5
        command  = ["CMD-SHELL", "/usr/bin/curl localhost:4444/healthz || exit 1"]
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.viz_vsm_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "viz_vsm"
        }
      }
    }
  ])

  memory                   = 2048
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.viz_vsm_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.viz_vsm_ecs_task_role.arn

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_service" "viz_vsm" {
  name                   = "viz_vsm_ecs_service"
  cluster                = aws_ecs_cluster.viz.id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.viz_vsm.arn
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.viz_vsm_ecs_task.id]
    subnets          = [aws_subnet.viz.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.viz_vsm,
    aws_iam_role.viz_vsm_ecs_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.viz_vsm.arn
    container_name   = "viz_vsm"
    container_port   = 4444
  }
  force_new_deployment = true
  tags = {
    SBO_Billing = "viz"
  }
  propagate_tags = "SERVICE"
}

resource "aws_iam_role" "viz_vsm_ecs_task_execution_role" {
  name = "viz_vsm-ecsTaskExecutionRole"

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
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_vsm_ecs_task_execution_role" {
  role       = aws_iam_role.viz_vsm_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "viz_vsm_ecs_task_role" {
  name = "viz_vsm-ecsTaskRole"
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
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_vsm_ecs_task_role_dockerhub" {
  role       = aws_iam_role.viz_vsm_ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.selected.arn
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "viz_vsm_ecs_exec" {
  name = "viz_vsm_ecs_exec_policy"
  role = aws_iam_role.viz_vsm_ecs_task_role.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "iam:GetRole",
          "iam:PassRole"
        ],
        "Resource" = "*"
      }
    ]
  })
}

#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "vsm_ecs_service_role" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:*"]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "viz_vsm_scaling_policy" {
  name   = "viz_vsm_scaling_policy"
  policy = data.aws_iam_policy_document.vsm_ecs_service_role.json

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role_policy_attachment" "viz_vsm_ecs_task_scaling" {
  role       = aws_iam_role.viz_vsm_ecs_task_role.name
  policy_arn = aws_iam_policy.viz_vsm_scaling_policy.arn
}
