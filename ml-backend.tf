################################################################################
# Resource definitions
################################################################################
resource "aws_cloudwatch_log_group" "ml_backend" {
  name              = "ml_backend"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "ml_backend"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_security_group" "ml_backend_ecs_task" {
  name        = "ml_backend_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for ML Reader webapp"

  tags = {
    Name        = "ml_backend_secgroup"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_ingress_rule" "ml_backend_allow_port_8080" {
  security_group_id = aws_security_group.ml_backend_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 http"

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_vpc_security_group_egress_rule" "ml_backend_allow_outgoing" {
  security_group_id = aws_security_group.ml_backend_ecs_task.id

  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow everything"

  tags = {
    SBO_Billing = "machinelearning"
  }
}


resource "aws_ecs_task_definition" "ml_backend_ecs_definition" {
  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0

  family       = "ml_backend_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 4096
      cpu         = 1024
      networkMode = "awsvpc"
      family      = "ml_backend"
      essential   = true
      image       = var.ml_backend_docker_image_url
      name        = "ml_backend"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8080
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "curl -f http://localhost:8080/healthz || exit 1"]
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      environment = [
        {
          name  = "DB_TYPE"
          value = "opensearch"
        },
        {
          name  = "DB_INDEX_PARAGRAPHS"
          value = "pubmed_paragraphs_reindexed"
        },
        {
          name  = "SEARCH_TYPE"
          value = "bm25"
        },
        {
          name  = "DB_HOST"
          value = "https://vpc-mlos-dvhdwgzvybiiyg2t7efsqke7pa.us-east-1.es.amazonaws.com"
        },
        {
          name  = "DB_PORT"
          value = 443
        },
      ]
      secrets = [
        {
          name      = "OPENAI_API_KEY"
          valueFrom = "${var.ml_secrets_arn}:OPENAI_API_KEY::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.ml_backend_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "ml_backend"
        }
      }
    }
  ])

  memory                   = 4096
  cpu                      = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_ml_backend_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_ml_backend_task_role[0].arn

  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_ecs_service" "ml_backend_ecs_service" {
  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0

  name            = "ml_backend_ecs_service"
  cluster         = aws_ecs_cluster.ml_ecs_cluster.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.ml_backend_ecs_definition[0].arn
  desired_count   = var.ml_backend_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  network_configuration {
    security_groups  = [aws_security_group.ml_backend_ecs_task.id]
    subnets          = [aws_subnet.machinelearning.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.ml_backend,
    aws_iam_role.ecs_ml_backend_task_execution_role, # wrong?
  ]
  lifecycle {
    ignore_changes = [desired_count]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.ml_backend.arn
    container_name   = "ml_backend"
    container_port   = 8080
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

resource "aws_iam_role" "ecs_ml_backend_task_execution_role" {
  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0
  name  = "ml_backend-ecsTaskExecutionRole"

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

resource "aws_iam_role_policy_attachment" "ecs_ml_backend_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_ml_backend_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_ml_backend_task_role" {
  count = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0
  name  = "ml_backend-ecsTaskRole"

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

resource "aws_iam_role_policy_attachment" "ecs_ml_backend_task_role_dockerhub_policy_attachment" {
  count      = var.ml_backend_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_ml_backend_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}
