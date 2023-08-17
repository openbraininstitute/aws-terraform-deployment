resource "aws_cloudwatch_log_group" "workflow" {
  # TODO check if the logs can be encrypted
  name              = var.workflow_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "workflow"
    SBO_Billing = "workflow"
  }
}

# TODO check: not used?
resource "aws_cloudwatch_log_group" "workflow_ecs" {
  # TODO check if the logs can be encrypted
  name              = "workflow_ecs"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "workflow"
    SBO_Billing = "workflow"
  }
}

resource "aws_ecs_cluster" "workflow" {
  name = "workflow_ecs_cluster"

  tags = {
    Application = "workflow"
    SBO_Billing = "workflow"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "workflow_ecs_task" {
  name        = "workflow_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for bbp-workflow"

  tags = {
    Name        = "workflow_secgroup"
    SBO_Billing = "workflow"
  }
}

resource "aws_vpc_security_group_ingress_rule" "workflow_allow_port_8100" {
  security_group_id = aws_security_group.workflow_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8100
  to_port     = 8100
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8100 HTTP"
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_vpc_security_group_ingress_rule" "workflow_allow_port_8082" {
  security_group_id = aws_security_group.workflow_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8082
  to_port     = 8082
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8082 HTTP"
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_vpc_security_group_ingress_rule" "workflow_allow_port_8080" {
  security_group_id = aws_security_group.workflow_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8080
  to_port     = 8080
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8080 HTTP"
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_vpc_security_group_egress_rule" "workflow_allow_outgoing_tcp" {
  security_group_id = aws_security_group.workflow_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all TCP"
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_vpc_security_group_egress_rule" "workflow_allow_outgoing_udp" {
  security_group_id = aws_security_group.workflow_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all UDP"
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_ecs_task_definition" "workflow_ecs_definition" {
  count = var.workflow_ecs_number_of_containers > 0 ? 1 : 0

  family       = "workflow_task_family"
  network_mode = "awsvpc"

  container_definitions = jsonencode([
    {
      memory      = 1024
      cpu         = 512
      networkMode = "awsvpc"
      family      = "workflow"
      essential   = true
      image       = var.workflow_docker_image_url
      name        = "workflow"
      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8100
          containerPort = 8100
          protocol      = "tcp"
        },
        {
          hostPort      = 8082
          containerPort = 8082
          protocol      = "tcp"
        },
        {
          hostPort      = 8080
          containerPort = 8080
          protocol      = "tcp"
        }
      ]
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      environment = [
        {
          name  = "ENVIRONMENT"
          value = "aws"
        },
        {
          name  = "USER"
          value = "bbp-workflow-sa"
        },
        {
          name  = "REDIRECT_URI"
          value = "https://bbp-workflow-api.shapes-registry.org/auth/?url=%s"
        },
        {
          name  = "KC_HOST"
          value = "https://sboauth.epfl.ch"
        },
        {
          name  = "KC_REALM"
          value = "SBO"
        },
        {
          name  = "HPC_HEAD_NODE"
          value = "sbo-poc-pcluster.shapes-registry.org"
        },
        {
          name  = "HPC_PATH_PREFIX"
          value = "/sbo/home"
        },
        {
          name  = "HPC_BBP_WORKFLOW_CNTNR"
          value = "/sbo/data/containers/py-bbp-workflow__3.1.32.dev2.sif"
        },
        {
          name  = "HPC_BRAYNS_CNTNR"
          value = "/sbo/data/containers/brayns__3.2.1.sif"
        },
        {
          name  = "HPC_NRDMS_HIPPOCAMPUS_CNTNR"
          value = "/sbo/data/containers/neurodamus-hippocampus__1.8-2.16.0-2.8.0.sif"
        },
        {
          name  = "HPC_NRDMS_NEOCORTEX_CNTNR"
          value = "/sbo/data/containers/neurodamus-neocortex__1.12-2.16.0-2.8.0.sif"
        },
        {
          name  = "HPC_NRDMS_NEOCORTEX_MULTISCALE_CNTNR"
          value = "/sbo/data/containers/neurodamus-neocortex-multiscale__1.12-2.16.0-2.8.0.sif"
        },
        {
          name  = "NEXUS_BASE"
          value = "https://sbo-nexus-delta.shapes-registry.org/v1"
        },
      ]
      secrets = [
        {
          name      = "SSH_PRIVATE_KEY"
          valueFrom = "${var.bbp_workflow_secrets_arn}:SSH_PRIVATE_KEY::"
        },
        {
          name      = "KC_SCR"
          valueFrom = "${var.bbp_workflow_secrets_arn}:KC_SCR::"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.workflow_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "workflow"
        }
      }
    }
  ])

  cpu                      = 512
  memory                   = 1024
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_workflow_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_workflow_task_role[0].arn

  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_ecs_service" "workflow_ecs_service" {
  count = var.workflow_ecs_number_of_containers > 0 ? 1 : 0

  name            = "workflow_ecs_service"
  cluster         = aws_ecs_cluster.workflow.id
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.workflow_ecs_definition[0].arn
  desired_count   = var.workflow_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.bbp_workflow_api.arn
    container_name   = "workflow"
    container_port   = 8100
  }

  network_configuration {
    security_groups  = [aws_security_group.workflow_ecs_task.id]
    subnets          = [aws_subnet.workflow.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.workflow,
    aws_iam_role.ecs_workflow_task_execution_role, # wrong?
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
    SBO_Billing = "workflow"
  }
}

resource "aws_iam_role" "ecs_workflow_task_execution_role" {
  count = var.workflow_ecs_number_of_containers > 0 ? 1 : 0
  name  = "workflow-ecsTaskExecutionRole"

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
    SBO_Billing = "workflow"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_workflow_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_workflow_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.workflow_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_workflow_task_role" {
  count = var.workflow_ecs_number_of_containers > 0 ? 1 : 0
  name  = "workflow-ecsTaskRole"

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
    SBO_Billing = "workflow"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_workflow_task_role_dockerhub_policy_attachment" {
  count      = var.workflow_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_workflow_task_execution_role[0].name
  policy_arn = aws_iam_policy.dockerhub_access.arn
}

resource "aws_iam_role_policy_attachment" "ecs_workflow_secrets_access_policy_attachment" {
  count      = var.workflow_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_workflow_task_execution_role[0].name
  policy_arn = aws_iam_policy.bbp_workflow_secrets_access.arn
}

