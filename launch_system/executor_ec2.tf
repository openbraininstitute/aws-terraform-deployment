# CPU executor capacity as ECS on EC2.
#
# Replaces Managed Instances: MI's InstanceLaunchTemplate has no userData (or custom AMI), so
# there is no way to premount EFS on the host. Per-task efsVolumeConfiguration then costs ~4s on
# every start. Owning the ASG lets user_data mount EFS once and expose it via hostPath (~1s).

data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

resource "aws_iam_role_policy_attachment" "executor_cpu_instance_ec2" {
  role       = aws_iam_role.executor_cpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_launch_template" "executor_cpu" {
  name_prefix            = "launch_system_executor_cpu"
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.executor_cpu_instance.arn
  }

  vpc_security_group_ids = [aws_security_group.executor_cpu_instance.id]

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.executor_cpu_volume_size_gib
      volume_type           = "gp3"
      throughput            = 250
      iops                  = 5000
      encrypted             = true
      delete_on_termination = true
    }
  }

  metadata_options {
    http_endpoint = "enabled"
    # Host networking shares the instance netns; hop limit 1 keeps IMDS off the task path.
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = false
  }

  user_data = base64encode(templatefile("${path.module}/user_data_executor.sh.tftpl", {
    cluster_name        = aws_ecs_cluster.executor.name
    aws_region          = var.aws_region
    reserved_memory_mib = var.executor_cpu_reserved_memory_mib

    public_data_efs_id             = var.public_launch_data_efs_id
    internal_public_data_efs_path  = var.internal_public_data_efs_path
    internal_public_data_host_path = local.executor_internal_public_data_host_path
    open_public_data_efs_path      = var.open_public_data_efs_path
    open_public_data_host_path     = local.executor_open_public_data_host_path

    shared_cache_efs_id    = aws_efs_file_system.executor_shared_cache.id
    shared_cache_efs_path  = local.executor_shared_cache_efs_path
    shared_cache_host_path = local.executor_shared_cache_host_path

    local_cache_host_path = local.executor_local_cache_host_path

    ecr_registry = local.executor_ecr_registry
    prepull_images = [
      var.default_executor_image_url,
      var.python_3_12_openmpi5_neuron9_neurodamus_executor_image_url,
    ]
  }))

  tag_specifications {
    resource_type = "instance"
    tags          = merge(var.tags, { Name = "launch_system_executor_cpu" })
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = "launch_system_executor_cpu" })
  }

  tags = merge(var.tags, { Name = "launch_system_executor_cpu" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "executor_cpu" {
  name_prefix         = "launch_system_executor_cpu"
  vpc_zone_identifier = local.executor_untrusted_subnet_ids

  min_size         = 0
  max_size         = var.executor_cpu_max_size
  desired_capacity = 0

  # Required when capacity-provider managed_termination_protection is ENABLED.
  protect_from_scale_in = true

  health_check_type         = "EC2"
  health_check_grace_period = 300

  mixed_instances_policy {
    instances_distribution {
      on_demand_percentage_above_base_capacity = 100
      spot_allocation_strategy                 = "price-capacity-optimized"
    }

    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.executor_cpu.id
        version            = "$Latest"
      }

      override {
        instance_requirements {
          vcpu_count {
            min = 16
            max = 64
          }

          memory_mib {
            min = 57344
            max = 294912
          }

          memory_gib_per_vcpu {
            min = 3.5
            max = 4.5
          }

          cpu_manufacturers     = ["intel", "amd"]
          instance_generations  = ["current"]
          burstable_performance = "excluded"
          accelerator_count {
            max = 0
          }

          # m5a ~3x slower on NEURON solve than m6a; h1/d3en are storage-optimised outliers.
          excluded_instance_types = ["m5a.*", "m5ad.*", "h1.*", "d3en.*"]
        }
      }
    }
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = "true"
    propagate_at_launch = false
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = "launch_system_executor_cpu" })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity]
  }
}

resource "aws_ecs_capacity_provider" "executor_cpu_ec2" {
  name = "launch_system_executor_cpu_ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.executor_cpu.arn
    managed_termination_protection = "ENABLED"
    managed_draining               = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = var.executor_cpu_target_capacity
      instance_warmup_period    = var.executor_cpu_instance_warmup
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = var.executor_cpu_max_scaling_step
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_cpu_ec2_capacity_provider" })

  depends_on = [
    aws_efs_mount_target.executor_shared_cache,
  ]
}
