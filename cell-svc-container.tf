# The security group for the EC2 systems that run the ECS cluster for cells
resource "aws_security_group" "cell_svc_ec2_ecs_instance_sg" {
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for SBO cell svc EC2 instance"

  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "cell_svc_ec2_ecs_instance_sg_ingress_tcp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id

  ip_protocol = "tcp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port * tcp"
  tags = {
    SBO_Billing = "cell_svc"
  }
}


resource "aws_vpc_security_group_ingress_rule" "cell_svc_ec2_ecs_instance_sg_ingress_udp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id

  ip_protocol = "udp"
  from_port   = 0
  to_port     = 65535
  cidr_ipv4   = data.terraform_remote_state.common.outputs.vpc_cidr_block
  description = "Allow port * udp"
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_vpc_security_group_egress_rule" "cell_svc_ec2_ecs_instance_sg_allow_outgoing_tcp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id
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

resource "aws_vpc_security_group_egress_rule" "cell_svc_ec2_ecs_instance_sg_allow_outgoing_udp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id
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



# IAM Role for the EC2 instances which will be used for the cells ECS
resource "aws_iam_role" "cells_ec2_instance_role" {
  name               = "Cells_EC2_InstanceRole"
  assume_role_policy = data.aws_iam_policy_document.cells_ec2_instance_role_policy.json
}

# Attach policy to role for ec2 instances for cells ecs cluster
resource "aws_iam_role_policy_attachment" "cells_ec2_instance_role_policy" {
  role       = aws_iam_role.cells_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# An IAM instance profile for the ec2 systems for the cells ecs cluster, based on the IAM role,
# for the ec2 launch template
resource "aws_iam_instance_profile" "cells_ec2_instance_role_profile" {
  name = "Cells_EC2_InstanceRoleProfile"
  role = aws_iam_role.cells_ec2_instance_role.id
}

# The iam policy doc to create the IAM role for the ec2 instances for the cells cluster
data "aws_iam_policy_document" "cells_ec2_instance_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "ecs.amazonaws.com"
      ]
    }
  }
}

# Launch template for the EC2 machines that will be used to run the ECS cluster/containers
resource "aws_launch_template" "cells_svc_ec2_launch_template" {
  name                   = "Cells_EC2_ECS_LaunchTemplate"
  image_id               = data.aws_ami.amazon_linux_2_ecs.id
  instance_type          = "t2.medium"
  key_name               = data.terraform_remote_state.common.outputs.aws_coreservices_ssh_key_id
  user_data              = base64encode(data.template_file.cells_ec2_ecs_user_data.rendered)
  vpc_security_group_ids = [aws_security_group.cell_svc_ec2_ecs_instance_sg.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.cells_ec2_instance_role_profile.arn
  }

  metadata_options {
    http_tokens = "required"
  }

  monitoring {
    enabled = true
  }
}

# The template for the user data script of the EC2 machines that will be used to run the cells ECS cluster
data "template_file" "cells_ec2_ecs_user_data" {
  template = file("cells_ec2_ecs_user_data.sh")

  vars = {
    ecs_cluster_name = "cell_svc_ecs_cluster"
  }
}
/*
# TODO no longer used
resource "aws_launch_configuration" "cell_svc_ecs_instance_config" {
  name = "cell_svc_ecs_instance_config"

  #Dries test iam_instance_profile = aws_iam_role.cell_svc_ecs_instance_role.name
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
}*/

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

# ECS cluster for cells
resource "aws_ecs_cluster" "cell_svc" {
  name = "cell_svc_ecs_cluster"

  tags = {
    Application = "cell_svc"
    SBO_Billing = "cell_svc"
  }
  lifecycle {
    create_before_destroy = true
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

# the task definition for the containers in ecs for cells
resource "aws_ecs_task_definition" "cell_svc_ecs_definition" {

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

  cpu                = 256
  memory             = 1024
  execution_role_arn = aws_iam_role.ecs_cell_svc_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_cell_svc_task_role.arn

  tags = {
    SBO_Billing = "cell_svc"
  }
}

# service for cells
resource "aws_ecs_service" "cell_svc_ecs_service" {
  #count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0

  name            = "cells_ecs_service"
  cluster         = aws_ecs_cluster.cell_svc.id
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.cell_svc_ecs_definition.arn
  desired_count   = var.cell_svc_ecs_number_of_containers
  # Doesn't work - iam_role                           = aws_iam_service_linked_role.cells_ecs_service_role.arn
  # How many percent of a service must be running to still execute a safe deployment
  deployment_minimum_healthy_percent = 0
  # How many additional tasks are allowed to run (in percent) while a deployment is executed
  deployment_maximum_percent = 100

  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cell_svc.arn
    container_name   = "cell_svc"
    container_port   = 8000
  }

  network_configuration {
    security_groups  = [aws_security_group.cell_svc_ecs_task.id]
    subnets          = [aws_subnet.cells.id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.cell_svc,
    aws_iam_role.ecs_cell_svc_task_execution_role #, # wrong?
    #aws_autoscaling_group.cell_svc_ecs_instance_asg
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

# Used by the ECS service to manage the cells ECS cluster
# so not for the ec2 systems and also not for the ecs containers
resource "aws_iam_role" "cells_ecs_service_role" {
  name               = "Cells_ECS_ServiceRole"
  assume_role_policy = data.aws_iam_policy_document.cells_ecs_service_policy.json
}

data "aws_iam_policy_document" "cells_ecs_service_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com", ]
    }
  }
}

# for ecs service role, not for the containers itself
resource "aws_iam_role_policy" "cells_ecs_service_role_policy" {
  name   = "Cells_ECS_ServiceRolePolicy"
  policy = data.aws_iam_policy_document.cells_ecs_service_role_policy.json
  role   = aws_iam_role.cells_ecs_service_role.id
}

# for ecs service role, not for the containers itself
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "cells_ecs_service_role_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets",
      "ec2:DescribeTags",
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:DescribeLogStreams",
      "logs:PutSubscriptionFilter",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role" "ecs_cell_svc_task_execution_role" {
  #count = var.cell_svc_ecs_number_of_containers > 0 ? 1 : 0
  name = "cell_svc-ecsTaskExecutionRole"

  assume_role_policy = data.aws_iam_policy_document.cells_ecs_task_assume_role_policy.json
  tags = {
    SBO_Billing = "cell_svc"
  }
}

data "aws_iam_policy_document" "cells_ecs_task_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_iam_role_policy_attachment" "ecs_cells_svc_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role" "ecs_cell_svc_task_role" {
  name               = "cell_svc-ecsTaskRole"
  assume_role_policy = data.aws_iam_policy_document.cells_ecs_task_assume_role_policy.json
}
/*
resource "aws_iam_role" "ecs_cell_svc_task_role" {
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
}*/

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = data.terraform_remote_state.common.outputs.dockerhub_access_iam_policy_arn
}

resource "aws_ecs_capacity_provider" "cells_cas" {
  name = "Cells_ECS_CapacityProvider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.cells_ecs_autoscaling_group.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      #maximum_scaling_step_size = 1
      #minimum_scaling_step_size = 1
      status = "ENABLED"
      #target_capacity           = 1
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.cell_svc.name
  capacity_providers = [aws_ecs_capacity_provider.cells_cas.name]
}

## Define Target Tracking on ECS Cluster Task level

resource "aws_appautoscaling_target" "cells_ecs_target" {
  max_capacity       = 1 # TODO
  min_capacity       = 1 # TODO
  resource_id        = "service/${aws_ecs_cluster.cell_svc.name}/${aws_ecs_service.cell_svc_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

## Policy for CPU tracking
resource "aws_appautoscaling_policy" "cells_ecs_cpu_policy" {
  name               = "Cells_CPUTargetTrackingScaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.cells_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cells_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.cells_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # Target tracking for CPU usage in %
    target_value = 90

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

## Policy for memory tracking
resource "aws_appautoscaling_policy" "cells_ecs_memory_policy" {
  name               = "cells_MemoryTargetTrackingScaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.cells_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.cells_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.cells_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # Target tracking for memory usage in %
    target_value = 80

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

## Creates an ASG linked with our main VPC
resource "aws_autoscaling_group" "cells_ecs_autoscaling_group" {
  name                  = "cells_ASG"
  max_size              = 1
  min_size              = 1
  vpc_zone_identifier   = [aws_subnet.cells.id]
  health_check_type     = "EC2"
  protect_from_scale_in = true

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]

  launch_template {
    id      = aws_launch_template.cells_svc_ec2_launch_template.id
    version = "$Latest"
  }

  instance_refresh {
    strategy = "Rolling"
  }

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key                 = "Name"
    value               = "Cells_ASG"
    propagate_at_launch = true
  }
}