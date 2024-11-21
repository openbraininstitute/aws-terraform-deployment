# Definition for sonata-cell-service

# Instead of running on Fargate, it currently runs on an EC2 instance
# (`cells_svc_ec2_launch_template`) which is called an "ECS Instance"
# This then hosts ECS "tasks"; which are the containers

# For now, only public data is used, and it is stored on the s3 bucket:
# ${var.cell_svc_perf_bucket_name}; this is mounted by sbo-cell-svc-perf-test
# and then made available to all ECS tasks.

# { EC2 Instance
# The security group for the EC2 systems that run the ECS cluster for cells
resource "aws_security_group" "cell_svc_ec2_ecs_instance_sg" {
  vpc_id      = var.vpc_id
  description = "Sec group for SBO cell svc EC2 instance"
  tags        = merge(var.tags, { Name = "cell_svc_ec2_ecs_instance_sg" })
}

resource "aws_vpc_security_group_ingress_rule" "cell_svc_ec2_ecs_instance_sg_ingress_tcp_udp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id
  ip_protocol       = -1
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow port * TCP/UDP ingress"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "cell_svc_ec2_ecs_instance_sg_egress_tcp_udp" {
  security_group_id = aws_security_group.cell_svc_ec2_ecs_instance_sg.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = var.vpc_cidr_block
  description = "Allow all TCP/UDP egress"
  tags        = var.tags
}

# { IAM Role for the EC2 instances which will be used for the cells ECS
#https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerServiceforEC2Role
resource "aws_iam_role" "cells_ec2_instance_role" {
  name_prefix        = "cl_ec2"
  assume_role_policy = data.aws_iam_policy_document.cells_ec2_instance_role_policy.json
  tags               = var.tags
}

# Attach policy to role for ec2 instances for cells ecs cluster
resource "aws_iam_role_policy_attachment" "cells_ec2_instance_role_policy" {
  role       = aws_iam_role.cells_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Give EC2 instance access to S3
resource "aws_iam_role_policy_attachment" "cells_ec2_instance_role_s3_policy" {
  role       = aws_iam_role.cells_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# An IAM instance profile for the ec2 systems for the cells ecs cluster, based on the IAM role,
# for the ec2 launch template
resource "aws_iam_instance_profile" "cells_ec2_instance_role_profile" {
  name_prefix = "cl_ins"
  role        = aws_iam_role.cells_ec2_instance_role.name
  tags        = var.tags
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
# } IAM Role for the EC2 instances which will be used for the cells ECS

# Launch template for the EC2 machines that will be used to run the ECS cluster/containers
resource "aws_launch_template" "cells_svc_ec2_launch_template" {
  name          = "cells_svc_ec2_launch_template"
  image_id      = var.amazon_linux_ecs_ami_id
  instance_type = "t2.medium"
  key_name      = var.aws_coreservices_ssh_key_id
  user_data = base64encode(templatefile("${path.module}/cells_ec2_ecs_user_data.sh", {
    cell_svc_perf_bucket_name = var.cell_svc_perf_bucket_name,
    ecs_cluster_name          = aws_ecs_cluster.cell_svc_ecs_cluster.name,
    ecs_cluster_tags          = join(",", [for k, v in var.tags : "\"${k}\": \"${v}\""])
  }))
  vpc_security_group_ids = [aws_security_group.cell_svc_ec2_ecs_instance_sg.id]
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.cells_ec2_instance_role_profile.arn
  }

  metadata_options {
    http_tokens = "required"
  }

  monitoring {
    enabled = true
  }

  tags = var.tags

  tag_specifications {
    resource_type = "instance"
    tags          = var.tags
  }

  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }
}

resource "aws_cloudwatch_log_group" "cell_svc" {
  # TODO check if the logs can be encrypted
  name              = var.cell_svc_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Application = "cell_svc" })
}

# TODO check: not used?
resource "aws_cloudwatch_log_group" "cell_svc_ecs" {
  # TODO check if the logs can be encrypted
  name_prefix       = "cl_log"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Application = "cell_svc" })
}

# ECS cluster for cells
resource "aws_ecs_cluster" "cell_svc_ecs_cluster" {
  name = "cell_svc_ecs_cluster"

  tags = merge(var.tags, { Application = "cell_svc" })

  lifecycle {
    create_before_destroy = true
  }
  setting {
    name  = "containerInsights"
    value = "disabled" #tfsec:ignore:aws-ecs-enable-container-insight
  }
}
# } EC2 Instance

# { ECS Task network
# TODO make more strict
resource "aws_security_group" "cell_svc_ecs_task" {
  name_prefix = "cl_tsk"
  vpc_id      = var.vpc_id
  description = "Sec group for SBO cell svc ECS task"

  tags = merge(var.tags, { Name = "cell_svc_ecs_task" })
}

resource "aws_vpc_security_group_ingress_rule" "cell_svc_task_ingress_port_8000" {
  security_group_id = aws_security_group.cell_svc_ecs_task.id
  ip_protocol       = "tcp"
  from_port         = 8000
  to_port           = 8000
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow port 8000 tcp for SBO cell svc ECS task"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "cell_svc_task_egress_tcp_udp" {
  security_group_id = aws_security_group.cell_svc_ecs_task.id
  # TODO limit to what is needed
  # needs access to dockerhub and to AWS secrets manager, likely also nexus, ...
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  #cidr_ipv4   = var.vpc_cidr_block
  description = "Allow all TCP/UDP egress"
  tags        = var.tags
}
# } ECS Task network

# { ECS Task
resource "aws_ecs_task_definition" "cell_svc_ecs_definition" {
  family = "cell_svc_task_family"

  requires_compatibilities = ["EC2"]

  execution_role_arn = aws_iam_role.ecs_cell_svc_task_execution_role.arn
  task_role_arn      = aws_iam_role.ecs_cell_svc_task_role.arn

  network_mode = "awsvpc"

  volume {
    name      = "sbo-project-data"
    host_path = "/sbo/data/project"
  }

  container_definitions = jsonencode([
    {
      memory      = 1536
      cpu         = 256
      networkMode = "awsvpc"
      family      = "sbocellsvc"
      essential   = true
      image       = var.cell_svc_docker_image_url
      name        = "cell_svc"

      repositoryCredentials = {
        credentialsParameter = var.dockerhub_credentials_arn
      }

      portMappings = [
        {
          hostPort      = 8000
          containerPort = 8000
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        {
          readOnly      = true
          sourceVolume  = "sbo-project-data"
          containerPath = "/sbo/data/project"
        }
      ]

      linuxParameters = {
        tmpfs = [
          {
            containerPath = "/tmp"
            size          = 512 # size in MiB
            mountOptions  = ["rw", "noexec", "nosuid"]
          }
        ]
      }

      environment = [
        {
          name  = "ROOT_PATH"
          value = var.root_path
        }
      ]

      healthcheck = {
        command     = ["CMD", "/code/scripts/healthcheck.sh"]
        interval    = 30
        timeout     = 5
        startPeriod = 5
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

  cpu    = 256
  memory = 1536

  tags = var.tags
}

resource "aws_ecs_service" "cell_svc_ecs_service" {
  name            = "cells_ecs_service"
  cluster         = aws_ecs_cluster.cell_svc_ecs_cluster.id
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.cell_svc_ecs_definition.arn
  desired_count   = var.cell_svc_ecs_number_of_containers

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 180

  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.private_cell_svc.arn
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
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  #triggers = {
  #  redeployment = timestamp()
  #}
  lifecycle {
    ignore_changes = [desired_count]
  }
  propagate_tags = "SERVICE"
  tags           = var.tags
}

# { Used by the ECS service to manage the cells ECS cluster
# *not* for the EC2 systems and also not for the ECS containers
resource "aws_iam_role" "cells_ecs_service_role" {
  name_prefix        = "cl_ecs"
  assume_role_policy = data.aws_iam_policy_document.cells_ecs_service_policy.json
  tags               = var.tags
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
  role   = aws_iam_role.cells_ecs_service_role.name
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
# } Used by the ECS service to manage the cells ECS cluster

# { ECS Task IAM
resource "aws_iam_role" "ecs_cell_svc_task_execution_role" {
  name_prefix        = "cl_exe"
  assume_role_policy = data.aws_iam_policy_document.cells_ecs_task_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role" "ecs_cell_svc_task_role" {
  name_prefix        = "cl_svc"
  assume_role_policy = data.aws_iam_policy_document.cells_ecs_task_assume_role_policy.json
  tags               = var.tags
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

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "cloudwatch_write_policy" {
  name        = "cl_cloudwatch_write_policy"
  description = "A policy that grants write access to Cloudwatch logs"

  policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Effect" : "Allow",
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents",
            "logs:DescribeLogStreams"
          ],
          "Resource" : [
            "arn:aws:logs:*:*:*"
          ]
        }
      ]
    }
  )

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_iam_role_policy_attachment" "ecs_cell_svc_task_role_dockerhub_policy_attachment" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = var.dockerhub_access_iam_policy_arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_write_logs" {
  role       = aws_iam_role.ecs_cell_svc_task_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_write_policy.arn
}
# }

# { Capacity provider; this creates or destroys EC2 *instances* to launch, on which ECS tasks are run
resource "aws_ecs_capacity_provider" "cells_cas" {
  name = "cells_ecs_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.cells_ecs_autoscaling_group.arn

    managed_scaling {
      #maximum_scaling_step_size = 1
      #minimum_scaling_step_size = 1
      status = "ENABLED"
      #target_capacity           = 1
    }
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.cell_svc_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.cells_cas.name]
}
# } Capacity provider

## Define Target Tracking on ECS Cluster Task level
resource "aws_appautoscaling_target" "cells_ecs_target" {
  max_capacity       = 1 # TODO
  min_capacity       = 1 # TODO
  resource_id        = "service/${aws_ecs_cluster.cell_svc_ecs_cluster.name}/${aws_ecs_service.cell_svc_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags               = var.tags
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
  name_prefix           = "cl_asg"
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

  instance_refresh { strategy = "Rolling" }
  lifecycle { create_before_destroy = true }

  tag {
    key                 = "Name"
    value               = "cells_autoscaling_group"
    propagate_at_launch = true
  }

  tag {
    key                 = "SBO_Billing"
    value               = "cell_svc"
    propagate_at_launch = true
  }
}
