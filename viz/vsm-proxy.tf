resource "aws_cloudwatch_log_group" "viz_vsm_proxy" {
  name              = "viz_vsm_proxy"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "viz_vsm_proxy"
    SBO_Billing = "viz"
  }
}

# TODO make more strict
resource "aws_security_group" "viz_vsm_proxy_ecs_task" {
  name        = "viz_vsm_proxy_ecs_task"
  vpc_id      = data.aws_vpc.selected.id
  description = "Sec group for VSM-Proxy service"

  tags = {
    Name        = "viz_vsm_proxy_secgroup"
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_ingress_rule" "viz_vsm_proxy_allow_port_8888" {
  security_group_id = aws_security_group.viz_vsm_proxy_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8888
  to_port     = 8888
  cidr_ipv4   = data.aws_vpc.selected.cidr_block
  description = "Allow port 8888 http"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_vpc_security_group_egress_rule" "viz_vsm_proxy_allow_outgoing" {
  security_group_id = aws_security_group.viz_vsm_proxy_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  description = "Allow everything"

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_task_definition" "viz_vsm_proxy_ecs_definition" {
  family       = "viz_vsm_proxy_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 2048
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "viz_vsm_proxy"
      essential   = true
      image       = var.viz_vsm_docker_image_url
      name        = "viz_vsm_proxy"
      repositoryCredentials = {
        credentialsParameter = data.aws_secretsmanager_secret.dockerhub_creds.arn
      }
      portMappings = [
        {
          hostPort      = 8888
          containerPort = 8888
          protocol      = "tcp"
        }
      ]
      command = [
        "-m",
        "vsm.slave",
        "--address",
        "0.0.0.0",
        "--port",
        "8888"
      ]
      environment = [
        {
          name  = "VSM_LOG_LEVEL"
          value = "DEBUG"
        },
        {
          name  = "VSM_DB_HOST"
          value = aws_db_instance.vizdb.address
        },
        {
          name  = "VSM_DB_USERNAME"
          value = var.viz_postgresql_database_username
        },
        {
          name  = "VSM_DB_NAME"
          value = var.viz_postgresql_database_name
        },
        {
          name  = "VSM_DB_PASSWORD"
          value = data.aws_secretsmanager_secret_version.viz_database_password.secret_string
        },
        {
          name  = "VSM_JOB_ALLOCATOR"
          value = "AWS"
        },
        {
          name  = "VSM_AWS_HOST"
          value = var.viz_brayns_hostname
        },
        {
          name  = "VSM_KEYCLOAK_URL"
          value = "https://sboauth.epfl.ch/auth/realms/SBO/protocol/openid-connect/userinfo"
        },
        {
          name  = "VSM_KEYCLOAK_HOST"
          value = "sboauth.epfl.ch"
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
        command  = ["CMD-SHELL", "/usr/bin/curl localhost:8888/healthz || exit 1"]
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.viz_vsm_proxy_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "viz_vsm_proxy"
        }
      }
    }
  ])

  memory                   = 2048
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.viz_vsm_proxy_ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.viz_vsm_proxy_ecs_task_role.arn

  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_ecs_service" "viz_vsm_proxy_ecs_service" {
  name                   = "viz_vsm_proxy_ecs_service"
  cluster                = aws_ecs_cluster.viz_ecs_cluster_2.id
  launch_type            = "FARGATE"
  task_definition        = aws_ecs_task_definition.viz_vsm_proxy_ecs_definition.arn
  desired_count          = 1
  enable_execute_command = true

  network_configuration {
    security_groups  = [aws_security_group.viz_vsm_proxy_ecs_task.id]
    subnets          = [aws_subnet.viz.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.viz_vsm_proxy,
    aws_iam_role.viz_vsm_proxy_ecs_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.viz_vsm_proxy.arn
    container_name   = "viz_vsm_proxy"
    container_port   = 8888
  }
  force_new_deployment = true
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_iam_role" "viz_vsm_proxy_ecs_task_execution_role" {
  name = "viz_vsm_proxy-ecsTaskExecutionRole"

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

resource "aws_iam_role_policy_attachment" "viz_vsm_proxy_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.viz_vsm_proxy_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "viz_vsm_proxy_ecs_task_role" {
  name = "viz_vsm_proxy-ecsTaskRole"
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

resource "aws_iam_role_policy_attachment" "viz_vsm_proxy_ecs_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.viz_vsm_proxy_ecs_task_execution_role.name
  policy_arn = data.aws_iam_policy.selected.arn
}

resource "aws_iam_role_policy" "viz_vsm_proxy_ecs_exec_policy" {
  name = "viz_vsm_proxy_ecs_exec_policy"
  role = aws_iam_role.viz_vsm_proxy_ecs_task_role.id
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Action" = [
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel"
        ],
        "Resource" = "*"
      }
    ]
  })
}
