resource "aws_security_group" "cell_svc_ecs_instance_sg" {
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO cell svc EC2 instance"

  # TODO limit to what is used.
  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    description = "Allow all outbound traffic"
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
  }
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_iam_role" "cell_svc_ecs_instance_role" {
  name = "cell_svc_ecs_instance_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_iam_role_policy_attachment" "cell_svc_ecs_instance_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
  role       = aws_iam_role.cell_svc_ecs_instance_role.name
}

resource "aws_launch_configuration" "cell_svc_ecs_instance_config" {
  name = "cell_svc_ecs_instance_config"

  iam_instance_profile = aws_iam_role.cell_svc_ecs_instance_role.name
  image_id             = data.aws_ami.amazonlinux.id
  instance_type        = "t2.medium"

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    encrypted = true
  }

  # TODO create a variable pointing to S3 with project data.
  user_data = <<-EOF
                        #!/bin/bash

                        echo ECS_CLUSTER=cell_svc_ecs_cluster >> /etc/ecs/ecs.config

                        wget https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.rpm
                        yum install -y ./mount-s3.rpm

                        mount-s3 sbo-cell-svc-perf-test /sbo/data/project
                        EOF

  security_groups = [aws_security_group.cell_svc_ecs_instance_sg.name]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "cell_svc_ecs_instance_asg" {
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_type         = "EC2"
  health_check_grace_period = 300 # 5 minutes
  force_delete              = true

  launch_configuration = aws_launch_configuration.cell_svc_ecs_instance_config.id

  tag {
    key                 = "SBO_Billing"
    value               = "cell_svc"
    propagate_at_launch = true
  }
}

resource "aws_cloudwatch_log_group" "cell_svc" {
  # TODO check if the logs can be encrypted
  name              = var.cell_svc_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "cell_svc"
    SBO_Billing = "cell_svc"
  }
}

# TODO check: not used?
resource "aws_cloudwatch_log_group" "cell_svc_ecs" {
  # TODO check if the logs can be encrypted
  name              = "cell_svc_ecs"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "cell_svc"
    SBO_Billing = "cell_svc"
  }
}

resource "aws_ecs_cluster" "cell_svc" {
  name = "cell_svc_ecs_cluster"

  tags = {
    Application = "cell_svc"
    SBO_Billing = "cell_svc"
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}

# TODO make more strict
resource "aws_security_group" "cell_svc_ecs_task" {
  name        = "cell_svc_ecs_task"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO cell svc"

  tags = {
    Name        = "cell_svc_secgroup"
    SBO_Billing = "cell_svc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cell_svc_allow_port_8000" {
  security_group_id = aws_security_group.cell_svc_ecs_task.id

  ip_protocol = "tcp"
  from_port   = 8000
  to_port     = 8000
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port 8000 http"
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_vpc_security_group_egress_rule" "cell_svc_allow_outgoing_tcp" {
  security_group_id = aws_security_group.cell_svc_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all TCP"
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_vpc_security_group_egress_rule" "cell_svc_allow_outgoing_udp" {
  security_group_id = aws_security_group.cell_svc_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow all UDP"
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_ecs_task_definition" "cell_svc_ecs_definition" {
  count = var.core_webapp_ecs_number_of_containers > 0 ? 1 : 0

  family       = "cell_svc_task_family"
  network_mode = "awsvpc"

  volume {
    name      = "sbo-project-data"
    host_path = "/sbo/data/project"
  }

  container_definitions = jsonencode([
    {
      memory      = 1024
      cpu         = 256
      networkMode = "awsvpc"
      family      = "sbocellsvc"
      essential   = true
      image       = var.cell_svc_docker_image_url
      name        = "cell_svc"
      repositoryCredentials = {
        credentialsParameter = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
      }
      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      mountPoints = [{
        sourceVolume  = "sbo-project-data"
        containerPath = "/sbo/data/project"
      }]
      healthcheck = {
        command     = ["CMD-SHELL", "exit 0"] // TODO: not exit 0
        interval    = 30
        timeout     = 5
        startPeriod = 60
        retries     = 3
      }
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.cell_svc_log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "cell_svc"
        }
      }
    }
  ])

  cpu                      = 256
  memory                   = 1024
  execution_role_arn       = aws_iam_role.ecs_cell_svc_task_execution_role[0].arn
  task_role_arn            = aws_iam_role.ecs_cell_svc_task_role[0].arn

  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_ecs_service" "cell_svc_ecs_service" {
  count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0

  name            = "core_webapp_ecs_service"
  cluster         = aws_ecs_cluster.cell_svc.id
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.cell_svc_ecs_definition[0].arn
  desired_count   = var.cell_svc_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  load_balancer {
    target_group_arn = aws_lb_target_group.cell_svc.arn
    container_name   = "cell_svc"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.cell_svc_ecs_task.id]
    subnets          = [aws_subnet.core_svc.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.cell_svc,
    aws_iam_role.ecs_cell_svc_task_execution_role, # wrong?
    aws_autoscaling_group.cell_svc_ecs_instance_asg
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
    SBO_Billing = "cell_svc"
  }
}

resource "aws_iam_role" "ecs_cell_svc_task_execution_role" {
  count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0
  name  = "cell_svc-ecsTaskExecutionRole"

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
    SBO_Billing = "cell_svc"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

  count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0
}

resource "aws_iam_role" "ecs_cell_svc_task_role" {
  count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0
  name  = "cell_svc-ecsTaskRole"

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
    SBO_Billing = "cell_svc"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_role_dockerhub_policy_attachment" {
  count      = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0
  role       = aws_iam_role.ecs_cell_svc_task_execution_role[0].name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}
