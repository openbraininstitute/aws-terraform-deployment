# { EC2 Instance
# The security group for the EC2 systems that run the ECS cluster
resource "aws_security_group" "obi_one_v2_ec2_ecs_instance_sg" {
  name        = "obi_one_v2_sg"
  vpc_id      = var.vpc_id
  description = "Sec group for EC2 instance"
  tags        = merge(var.tags, { Name = "obi_one_v2_ec2_ecs_instance_sg" })
}

resource "aws_vpc_security_group_ingress_rule" "obi_one_v2_ec2_ecs_instance_sg_ingress_tcp_udp" {
  security_group_id = aws_security_group.obi_one_v2_ec2_ecs_instance_sg.id
  ip_protocol       = -1
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow port * TCP/UDP ingress"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "obi_one_v2_ec2_ecs_instance_sg_egress_tcp_udp" {
  security_group_id = aws_security_group.obi_one_v2_ec2_ecs_instance_sg.id
  # TODO limit to what is needed, needs access to ECR and to AWS secrets manager at least
  ip_protocol = -1
  cidr_ipv4   = "0.0.0.0/0"
  # cidr_ipv4   = var.vpc_cidr_block
  description = "Allow all TCP/UDP egress"
  tags        = var.tags
}

# { IAM Role for the EC2 instances which will be used for the ECS
#https://docs.aws.amazon.com/AmazonECS/latest/developerguide/security-iam-awsmanpol.html#security-iam-awsmanpol-AmazonEC2ContainerServiceforEC2Role
resource "aws_iam_role" "obi_one_v2_ec2_instance_role" {
  name_prefix        = "obi-one-v2-ec2"
  assume_role_policy = data.aws_iam_policy_document.obi_one_v2_ec2_instance_role_policy.json
  tags               = var.tags
}

# Attach policy to role for ec2 instances for the ecs cluster
resource "aws_iam_role_policy_attachment" "obi_one_v2_ec2_instance_role_policy" {
  role       = aws_iam_role.obi_one_v2_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# Give EC2 instance access to S3
resource "aws_iam_role_policy_attachment" "obi_one_v2_ec2_instance_role_s3_policy" {
  role       = aws_iam_role.obi_one_v2_ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
}

# An IAM instance profile for the ec2 systems for the ecs cluster, based on the IAM role,
# for the ec2 launch template
resource "aws_iam_instance_profile" "obi_one_v2_ec2_instance_role_profile" {
  name_prefix = "obi-one-v2-ec2"
  role        = aws_iam_role.obi_one_v2_ec2_instance_role.name
  tags        = var.tags
}

# The iam policy doc to create the IAM role for the ec2 instances for the cluster
data "aws_iam_policy_document" "obi_one_v2_ec2_instance_role_policy" {
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
# } IAM Role for the EC2 instances which will be used for the ECS

# Launch template for the EC2 machines that will be used to run the ECS cluster/containers
resource "aws_launch_template" "obi_one_v2_ec2_launch_template" {
  name          = "obi_one_v2_ec2_launch_template"
  image_id      = var.amazon_linux_ecs_ami_id
  instance_type = var.ec2_instance_type
  key_name      = var.aws_coreservices_ssh_key_id
  user_data = base64encode(templatefile("${path.module}/ec2_ecs_user_data.sh", {
    mount_base_dir   = var.mount_base_dir,
    mount_buckets    = var.mount_buckets,
    ecs_cluster_name = aws_ecs_cluster.obi_one_v2_ecs_cluster.name,
    ecs_cluster_tags = join(",", [for k, v in var.tags : "\"${k}\": \"${v}\""]),
  }))
  vpc_security_group_ids = [aws_security_group.obi_one_v2_ec2_ecs_instance_sg.id]
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.obi_one_v2_ec2_instance_role_profile.arn
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

resource "aws_cloudwatch_log_group" "obi_one_v2" {
  # TODO check if the logs can be encrypted
  name              = var.log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = merge(var.tags, { Application = "obi_one_v2" })
}

# ECS cluster
resource "aws_ecs_cluster" "obi_one_v2_ecs_cluster" {
  name = "obi_one_v2_ecs_cluster"

  tags = merge(var.tags, { Application = "obi_one_v2" })

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
resource "aws_security_group" "obi_one_v2_ecs_task" {
  name_prefix = "obi-one-v2-ecs"
  vpc_id      = var.vpc_id
  description = "Sec group for ECS task"

  tags = merge(var.tags, { Name = "obi_one_v2_ecs_task" })
}

resource "aws_vpc_security_group_ingress_rule" "obi_one_v2_task_ingress_container_port" {
  security_group_id = aws_security_group.obi_one_v2_ecs_task.id
  ip_protocol       = "tcp"
  from_port         = var.container_port
  to_port           = var.container_port
  cidr_ipv4         = var.vpc_cidr_block
  description       = "Allow container_port tcp for ECS task"
  tags              = var.tags
}

resource "aws_vpc_security_group_egress_rule" "obi_one_v2_task_egress_tcp_udp" {
  security_group_id = aws_security_group.obi_one_v2_ecs_task.id
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
resource "aws_ecs_task_definition" "obi_one_v2_ecs_definition" {
  family = "obi_one_v2_task_family"

  requires_compatibilities = ["EC2"]

  execution_role_arn = aws_iam_role.obi_one_v2_ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.obi_one_v2_ecs_task_role.arn

  network_mode = "awsvpc"

  dynamic "volume" {
    for_each = var.mount_buckets
    content {
      name      = volume.value.volume_name
      host_path = "${var.mount_base_dir}${volume.value.volume_host_path}"
    }
  }

  container_definitions = jsonencode([
    {
      memory      = var.ecs_task_size.memory
      cpu         = var.ecs_task_size.cpu
      networkMode = "awsvpc"
      essential   = true
      image       = var.docker_image_url
      name        = "obi_one_v2"

      portMappings = [
        {
          hostPort      = var.host_port
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]

      mountPoints = [
        for m in var.mount_buckets :
        {
          readOnly      = true
          sourceVolume  = m.volume_name
          containerPath = "${var.mount_base_dir}${m.volume_container_path}"
        }
      ]

      linuxParameters = {
        tmpfs = [
          {
            containerPath = "/tmp"
            size          = var.ecs_task_size.tmpfs
            mountOptions  = ["rw", "noexec", "nosuid"]
          }
        ]
      }

      environment = [
        {
          name  = "APP_DEBUG"
          value = "false"
        },
        {
          name  = "CORS_ORIGINS"
          value = jsonencode(var.cors_origins)
        },
        {
          name  = "ROOT_PATH"
          value = var.root_path
        },
        {
          name  = "MOUNT_BASE_DIR"
          value = var.mount_base_dir
        },
        {
          name  = "KEYCLOAK_URL"
          value = var.keycloak_url
        },
        {
          name  = "ENTITYCORE_URL"
          value = var.entitycore_url
        },
        {
          name  = "LAUNCH_SYSTEM_URL"
          value = var.launch_system_url
        },
      ]

      healthcheck = {
        # command     = ["CMD", "/code/scripts/healthcheck.sh"]
        command     = ["CMD-SHELL", "exit 0"] // TODO: add a proper health check
        interval    = 30
        timeout     = 5
        startPeriod = 5
        retries     = 3
      }

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = var.log_group_name
          awslogs-region        = var.aws_region
          awslogs-create-group  = "true"
          awslogs-stream-prefix = "obi_one_v2"
        }
      }
    }
  ])

  cpu    = var.ecs_task_size.cpu
  memory = var.ecs_task_size.memory

  tags = var.tags
}

resource "aws_ecs_service" "obi_one_v2_ecs_service" {
  name            = "obi_one_v2_service"
  cluster         = aws_ecs_cluster.obi_one_v2_ecs_cluster.id
  task_definition = aws_ecs_task_definition.obi_one_v2_ecs_definition.arn
  desired_count   = var.obi_one_v2_ecs_number_of_containers

  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  health_check_grace_period_seconds  = 180

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.obi_one_v2_cas.name
    weight            = 1
  }

  ## Make use of all available space on the Container Instances
  ordered_placement_strategy {
    type  = "binpack"
    field = "memory"
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.private_obi_one_v2.arn
    container_name   = "obi_one_v2"
    container_port   = var.container_port
  }

  network_configuration {
    security_groups  = [aws_security_group.obi_one_v2_ecs_task.id]
    subnets          = [aws_subnet.obi_one_v2.id]
    assign_public_ip = false
  }

  depends_on = [
    aws_cloudwatch_log_group.obi_one_v2,
    aws_iam_role.obi_one_v2_ecs_task_execution_role #, # wrong?
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

# { Used by the ECS service to manage the ECS cluster
# *not* for the EC2 systems and also not for the ECS containers
resource "aws_iam_role" "obi_one_v2_ecs_service_role" {
  name_prefix        = "obi-one-v2-ecs"
  assume_role_policy = data.aws_iam_policy_document.obi_one_v2_ecs_service_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "obi_one_v2_ecs_service_policy" {
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
resource "aws_iam_role_policy" "obi_one_v2_ecs_service_role_policy" {
  name   = "obi_one_v2_ECS_ServiceRolePolicy"
  policy = data.aws_iam_policy_document.obi_one_v2_ecs_service_role_policy.json
  role   = aws_iam_role.obi_one_v2_ecs_service_role.name
}

# for ecs service role, not for the containers itself
#tfsec:ignore:aws-iam-no-policy-wildcards
data "aws_iam_policy_document" "obi_one_v2_ecs_service_role_policy" {
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
# } Used by the ECS service to manage the ECS cluster

# { ECS Task IAM
resource "aws_iam_role" "obi_one_v2_ecs_task_execution_role" {
  name_prefix        = "obi-one-v2-ecs-exe"
  assume_role_policy = data.aws_iam_policy_document.obi_one_v2_ecs_task_assume_role_policy.json
  tags               = var.tags
}

resource "aws_iam_role" "obi_one_v2_ecs_task_role" {
  name_prefix        = "obi-one-v2-ecs-svc"
  assume_role_policy = data.aws_iam_policy_document.obi_one_v2_ecs_task_assume_role_policy.json
  tags               = var.tags
}

data "aws_iam_policy_document" "obi_one_v2_ecs_task_assume_role_policy" {
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
  name        = "obi_one_v2_cloudwatch_write_policy"
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

resource "aws_iam_role_policy_attachment" "obi_one_v2_ecs_task_execution_role_policy_attachment" {
  role       = aws_iam_role.obi_one_v2_ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"

}

resource "aws_iam_role_policy_attachment" "cloudwatch_write_logs" {
  role       = aws_iam_role.obi_one_v2_ecs_task_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_write_policy.arn
}
# }

# { Capacity provider; this creates or destroys EC2 *instances* to launch, on which ECS tasks are run
resource "aws_ecs_capacity_provider" "obi_one_v2_cas" {
  name = "obi_one_v2_ecs_capacity_provider"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.obi_one_v2_ecs_autoscaling_group.arn
    managed_termination_protection = "ENABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1
    }
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "cas" {
  cluster_name       = aws_ecs_cluster.obi_one_v2_ecs_cluster.name
  capacity_providers = [aws_ecs_capacity_provider.obi_one_v2_cas.name]
}
# } Capacity provider

## Define Target Tracking on ECS Cluster Task level
resource "aws_appautoscaling_target" "obi_one_v2_ecs_target" {
  max_capacity       = 1 # TODO
  min_capacity       = 1 # TODO
  resource_id        = "service/${aws_ecs_cluster.obi_one_v2_ecs_cluster.name}/${aws_ecs_service.obi_one_v2_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
  tags               = var.tags
}

## Policy for CPU tracking
resource "aws_appautoscaling_policy" "obi_one_v2_ecs_cpu_policy" {
  name               = "obi_one_v2_CPUTargetTrackingScaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.obi_one_v2_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.obi_one_v2_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.obi_one_v2_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # Target tracking for CPU usage in %
    target_value = 90

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
  }
}

## Policy for memory tracking
resource "aws_appautoscaling_policy" "obi_one_v2_ecs_memory_policy" {
  name               = "obi_one_v2_MemoryTargetTrackingScaling"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.obi_one_v2_ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.obi_one_v2_ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.obi_one_v2_ecs_target.service_namespace

  target_tracking_scaling_policy_configuration {
    # Target tracking for memory usage in %
    target_value = 80

    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
  }
}

## Creates an ASG linked with our main VPC
resource "aws_autoscaling_group" "obi_one_v2_ecs_autoscaling_group" {
  name_prefix           = "obi-one-v2-ecs-asg"
  max_size              = 2
  min_size              = 1
  desired_capacity      = 1
  vpc_zone_identifier   = [aws_subnet.obi_one_v2.id]
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
    id      = aws_launch_template.obi_one_v2_ec2_launch_template.id
    version = aws_launch_template.obi_one_v2_ec2_launch_template.latest_version
  }

  instance_refresh { strategy = "Rolling" }
  lifecycle { create_before_destroy = true }

  tag {
    key                 = "Name"
    value               = "obi_one_v2_autoscaling_group"
    propagate_at_launch = true
  }

  tag {
    key                 = "SBO_Billing"
    value               = "obi_one_v2"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}
