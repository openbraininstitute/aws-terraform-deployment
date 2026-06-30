locals {
  # Prioritized fallbacks when g6e.4xlarge has no AZ capacity (common for L40S SKUs).
  # All types below provide >= 64 GiB RAM and 1 GPU.
  executor_gpu_instance_types = [
    # 16 vCPU / 128 GiB / 1x NVIDIA L40S (48 GB VRAM)
    "g6e.4xlarge",
    # 16 vCPU / 128 GiB / 1x NVIDIA RTX PRO 6000 Blackwell Server Edition
    "g7e.4xlarge",
    # 8 vCPU / 64 GiB / 1x NVIDIA L40S (48 GB VRAM)
    "g6e.2xlarge",
    # 16 vCPU / 64 GiB / 1x NVIDIA A10G (24 GB VRAM)
    "g5.4xlarge",
  ]
}

data "aws_ssm_parameter" "executor_gpu_ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/gpu/recommended/image_id"
}

data "aws_iam_policy_document" "executor_gpu_ec2_instance_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "executor_gpu_ec2_instance" {
  name_prefix        = "launch_system_executor_gpu_ec2"
  assume_role_policy = data.aws_iam_policy_document.executor_gpu_ec2_instance_role_assume.json
}

resource "aws_iam_role_policy_attachment" "executor_gpu_ec2_instance_ecs" {
  role       = aws_iam_role.executor_gpu_ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_role_policy_attachment" "executor_gpu_ec2_instance_ssm" {
  role       = aws_iam_role.executor_gpu_ec2_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "executor_gpu_ec2_instance" {
  name_prefix = "launch_system_executor_gpu_ec2"
  role        = aws_iam_role.executor_gpu_ec2_instance.name
}

resource "aws_security_group" "executor_gpu_ec2_instance" {
  name_prefix = "launch_system_executor_gpu_ec2"
  vpc_id      = var.vpc_id
  description = "Security group for launch system executor GPU ECS instances"

  tags = merge(var.tags, { Name = "launch_system_executor_gpu_ec2_instance" })
}

resource "aws_vpc_security_group_egress_rule" "executor_gpu_ec2_instance_allow_outgoing" {
  security_group_id = aws_security_group.executor_gpu_ec2_instance.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress for ECS GPU instances"
}

resource "aws_launch_template" "executor_gpu_ec2" {
  name_prefix   = "launch-system-executor-gpu-"
  image_id      = data.aws_ssm_parameter.executor_gpu_ecs_ami.value
  instance_type = local.executor_gpu_instance_types[0]
  user_data = base64encode(templatefile("${path.module}/templates/executor_gpu_ec2_userdata.sh.tftpl", {
    ecs_cluster_name = aws_ecs_cluster.executor.name
  }))
  update_default_version = true

  vpc_security_group_ids = [aws_security_group.executor_gpu_ec2_instance.id]

  iam_instance_profile {
    arn = aws_iam_instance_profile.executor_gpu_ec2_instance.arn
  }

  metadata_options {
    http_tokens = "required"
  }

  monitoring {
    enabled = true
  }

  dynamic "tag_specifications" {
    for_each = toset(["instance", "volume"])
    content {
      resource_type = tag_specifications.value
      tags = merge(var.tags, {
        Name = "launch_system_executor_gpu_ec2"
      })
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_gpu_launch_template" })
}

resource "aws_autoscaling_group" "executor_gpu_ec2" {
  name_prefix = "launch-system-executor-gpu-"
  # Pay-per-use: no GPU EC2 instances run until the ECS capacity provider scales out for a task.
  min_size              = 0
  max_size              = 4
  desired_capacity      = 0
  health_check_type     = "EC2"
  protect_from_scale_in = false
  vpc_zone_identifier   = local.executor_untrusted_subnet_ids
  capacity_rebalance    = true
  default_cooldown      = 60

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.executor_gpu_ec2.id
        version            = aws_launch_template.executor_gpu_ec2.latest_version
      }

      dynamic "override" {
        for_each = local.executor_gpu_instance_types
        content {
          instance_type = override.value
        }
      }
    }
    instances_distribution {
      on_demand_allocation_strategy            = "prioritized"
      on_demand_base_capacity                  = 0
      on_demand_percentage_above_base_capacity = 100
    }
  }

  lifecycle {
    create_before_destroy = true
    # Managed scaling sets desired_capacity when tasks arrive; scale-in returns to 0 when idle.
    # Ignore so terraform apply does not reset desired_capacity while tasks are provisioning.
    ignore_changes = [desired_capacity]
  }

  tag {
    key                 = "Name"
    value               = "launch_system_executor_gpu_asg"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }

  dynamic "tag" {
    for_each = var.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

resource "aws_ecs_capacity_provider" "executor_gpu" {
  name = "launch_system_executor_gpu_ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.executor_gpu_ec2.arn
    managed_termination_protection = "DISABLED"
    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 100
      minimum_scaling_step_size = 1
      # One pending task → one new container instance per scaling action.
      maximum_scaling_step_size = 1
      instance_warmup_period    = 300
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_gpu_ec2_capacity_provider" })
}

resource "aws_ecs_task_definition" "python_3_12_compiler_cuda_12_8_executor" {
  family                   = "launch_system_python_3_12_compiler_cuda_12_8_executor_task_family"
  network_mode             = "awsvpc"
  cpu                      = tostring(var.executor_task_size.cpu)
  memory                   = tostring(var.executor_task_size.memory)
  requires_compatibilities = ["EC2"]
  execution_role_arn       = local.executor_base_config.default_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.python_3_12_compiler_cuda_12_8_image_url
      environment = [
        {
          name  = "EXECUTOR_NAME"
          value = "python_3_12_compiler_cuda_12_8"
        }
      ]
      resourceRequirements = [
        {
          type  = "GPU"
          value = "1"
        }
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_python_3_12_compiler_cuda_12_8_executor"
        })
      })
    })
  ])

  dynamic "volume" {
    for_each = local.executor_volumes
    content {
      name = volume.value.name
      efs_volume_configuration {
        file_system_id     = volume.value.efs_volume_configuration.file_system_id
        transit_encryption = volume.value.efs_volume_configuration.transit_encryption
        authorization_config {
          access_point_id = volume.value.efs_volume_configuration.authorization_config.access_point_id
          iam             = volume.value.efs_volume_configuration.authorization_config.iam
        }
      }
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}
