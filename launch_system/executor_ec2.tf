# CPU capacity for the launch-system executors, as ECS on EC2.
#
# This replaces the Managed Instances provider. The reason for owning the instances is control
# over their bootstrap: EFS can then be mounted once per instance instead of once per task, and
# images can be pre-pulled. Managed Instances exposes no instance-launch hook at all --
# InstanceLaunchTemplate has no userData and no imageId -- so neither is possible there.
#
# What we take on in exchange: the AMI, its patch cadence, instance replacement and the scaling
# configuration, all of which Managed Instances handled.

# Tracks the current ECS-optimised AL2023 AMI. Pinned to a specific image id in state at apply
# time, so a new AMI release only rolls out when this is re-applied.
data "aws_ssm_parameter" "ecs_optimized_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2023/recommended/image_id"
}

# ------------------------------------------------------------------------------------------------
# Instance role. The Managed Instances variant of this used
# AmazonECSInstanceRolePolicyForManagedInstances; a self-managed instance needs the EC2 container
# service role instead, which grants cluster registration and image pulls.
# ------------------------------------------------------------------------------------------------
resource "aws_iam_role_policy_attachment" "executor_cpu_instance_ec2" {
  role       = aws_iam_role.executor_cpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# ------------------------------------------------------------------------------------------------
# Launch template.
# ------------------------------------------------------------------------------------------------
resource "aws_launch_template" "executor_cpu" {
  name_prefix            = "launch_system_executor_cpu"
  image_id               = data.aws_ssm_parameter.ecs_optimized_ami.value
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.executor_cpu_instance.arn
  }

  vpc_security_group_ids = [aws_security_group.executor_cpu_instance.id]

  # Single volume holding the OS, the image cache and the local task cache. Sized to match the
  # 200 GiB the Managed Instances provider attached, and gp3 so throughput does not scale with
  # size the way gp2 does.
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
    # IMDSv2 only. Tasks use host networking, so they share the instance's network namespace and
    # could otherwise reach IMDS; a hop limit of 1 keeps the credentials off the task's path.
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    # DETAILED bills per-minute host metrics per instance, which we do not consume.
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

# ------------------------------------------------------------------------------------------------
# Auto Scaling group. The instance_requirements block mirrors the Managed Instances provider so
# the instance pool is unchanged -- see the comments there for why each bound is what it is.
# ------------------------------------------------------------------------------------------------
resource "aws_autoscaling_group" "executor_cpu" {
  name_prefix         = "launch_system_executor_cpu"
  vpc_zone_identifier = local.executor_untrusted_subnet_ids

  # ECS managed scaling drives the desired count; starting at zero keeps an apply from launching
  # instances before any work exists.
  min_size         = 0
  max_size         = var.executor_cpu_max_size
  desired_capacity = 0

  # Required by managed_termination_protection on the capacity provider: ECS marks instances
  # running tasks as protected, and the group must honour that.
  protect_from_scale_in = true

  # An instance that fails its EC2 health check is replaced. This is the equivalent of the
  # Managed Instances auto_repair_configuration.
  health_check_type         = "EC2"
  health_check_grace_period = 300

  mixed_instances_policy {
    instances_distribution {
      # On-demand only, matching Managed Instances. Spot would interrupt simulations mid-run.
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

          # m5a/m5ad are Zen 1 and measured ~3x slower on the NEURON solve than m6a; h1/d3en are
          # older storage-optimised families that happen to satisfy the ratio band.
          excluded_instance_types = ["m5a.*", "m5ad.*", "h1.*", "d3en.*"]
        }
      }
    }
  }

  # ECS discovers the group through this tag.
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

  # The template is versioned and replaced on change; the group follows rather than being
  # recreated, so running tasks are not disturbed by an unrelated edit.
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 0
      instance_warmup        = 300
    }
  }

  lifecycle {
    create_before_destroy = true
    # Managed scaling owns this; a terraform diff on it would fight the ECS scaler.
    ignore_changes = [desired_capacity]
  }
}

# ------------------------------------------------------------------------------------------------
# Capacity provider.
# ------------------------------------------------------------------------------------------------
resource "aws_ecs_capacity_provider" "executor_cpu_ec2" {
  name = "launch_system_executor_cpu_ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn = aws_autoscaling_group.executor_cpu.arn

    # Lets ECS hold an instance back from scale-in while it still runs tasks.
    managed_termination_protection = "ENABLED"
    # Drains tasks off an instance being terminated instead of killing them outright.
    managed_draining = "ENABLED"

    managed_scaling {
      status = "ENABLED"
      # Below 100 ECS keeps spare capacity, which is the closest equivalent to the Managed
      # Instances scale_in_after idle window: headroom for the next task without a cold launch.
      target_capacity = var.executor_cpu_target_capacity

      # Instances take a while to boot, mount EFS and pre-pull images; without a warmup the
      # scaler counts them as available too early and over-provisions.
      instance_warmup_period    = var.executor_cpu_instance_warmup
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = var.executor_cpu_max_scaling_step
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_cpu_ec2_capacity_provider" })

  # Mount targets must exist before the first instance boots and runs user_data NFS mounts.
  depends_on = [
    aws_efs_mount_target.executor_shared_cache,
  ]
}
