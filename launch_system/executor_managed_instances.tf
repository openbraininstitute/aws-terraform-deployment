data "aws_iam_policy_document" "executor_cpu_infrastructure_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "executor_cpu_infrastructure" {
  name               = "launch_system_executor_cpu_infrastructure"
  assume_role_policy = data.aws_iam_policy_document.executor_cpu_infrastructure_role_assume.json
}

resource "aws_iam_role_policy_attachment" "executor_cpu_infrastructure_managed_instances" {
  role       = aws_iam_role.executor_cpu_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForManagedInstances"
}

data "aws_iam_policy_document" "executor_cpu_infrastructure_pass_instance_role" {
  statement {
    sid    = "PassInstanceRoleToEC2"
    effect = "Allow"

    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.executor_cpu_instance.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ec2.*"]
    }
  }
}

resource "aws_iam_role_policy" "executor_cpu_infrastructure_pass_instance_role" {
  name   = "pass-instance-role"
  role   = aws_iam_role.executor_cpu_infrastructure.id
  policy = data.aws_iam_policy_document.executor_cpu_infrastructure_pass_instance_role.json
}

data "aws_iam_policy_document" "executor_cpu_instance_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "executor_cpu_instance" {
  name               = "launch_system_executor_cpu_instance"
  assume_role_policy = data.aws_iam_policy_document.executor_cpu_instance_role_assume.json
}

resource "aws_iam_role_policy_attachment" "executor_cpu_instance_managed_instances" {
  role       = aws_iam_role.executor_cpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInstanceRolePolicyForManagedInstances"
}

resource "aws_iam_role_policy_attachment" "executor_cpu_instance_ssm" {
  role       = aws_iam_role.executor_cpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "executor_cpu_instance" {
  name = "launch_system_executor_cpu_instance"
  role = aws_iam_role.executor_cpu_instance.name
}

resource "aws_security_group" "executor_cpu_instance" {
  name_prefix = "launch_system_executor_cpu"
  vpc_id      = var.vpc_id
  description = "Security group for launch system executor CPU ECS managed instances"

  tags = merge(var.tags, { Name = "launch_system_executor_cpu_instance" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "executor_cpu_instance_allow_outgoing" {
  security_group_id = aws_security_group.executor_cpu_instance.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress for ECS CPU instances"
}

# Deliberately no S3 Files ingress rule here: mounts use the TASK ENI, so the task security
# group governs them (see `s3files_nfs_from_executor` in s3files.tf). Verified in sandbox-nse.
# Only image pulls, secrets and logs use the instance ENI.

resource "aws_ecs_capacity_provider" "executor_cpu" {
  name    = "launch_system_executor_cpu"
  cluster = aws_ecs_cluster.executor.name

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.executor_cpu_infrastructure.arn
    propagate_tags          = "CAPACITY_PROVIDER"

    # Replace unhealthy instances rather than let them keep attracting placements, which
    # scale_in_after would otherwise prolong. Pinned because the attribute is computed, so the
    # inherited default could change without a diff. Repair kills running tasks; acceptable
    # since executors are re-runnable and the orchestrator retries.
    auto_repair_configuration {
      actions_status = "ENABLED"
    }

    infrastructure_optimization {
      # Keep empty instances available to reduce cold starts between jobs. See the variable
      # description for the idle-cost tradeoff.
      scale_in_after = var.executor_cpu_scale_in_after
    }

    instance_launch_template {
      ec2_instance_profile_arn = aws_iam_instance_profile.executor_cpu_instance.arn
      # Default; DETAILED bills 1-minute host metrics per instance, which we do not use.
      monitoring = "BASIC"

      network_configuration {
        subnets         = local.executor_untrusted_subnet_ids
        security_groups = [aws_security_group.executor_cpu_instance.id]
      }

      # Shared by images, writable layers and task scratch; replaces per-task Fargate
      # ephemeral storage. Note there is no per-task quota on this volume.
      storage_configuration {
        storage_size_gib = 200
      }

      # Attribute-based selection: state the requirements, let ECS pick the instance type.
      #
      # 16 vCPU floor is a cost choice -- smallest size meeting the ratio below, and ECS picks
      # something larger when a task does not fit. Density is bound by cpu/memory, NOT by ENIs:
      # Managed Instances attaches a trunk ENI and gives each task a branch ENI, so the
      # one-ENI-per-task ceiling and the awsvpcTrunking setting do not apply (documented limit
      # is 60 tasks on a 4xlarge; 12 concurrent tasks on one m6a.4xlarge verified in sandbox).
      instance_requirements {
        vcpu_count {
          min = 16
          max = 64
        }

        # Derived from the vCPU range x the ratio band below (16x3.5=56 GiB, 64x4.5=288 GiB).
        # Keep in step: a tighter floor here would override the ratio's lower bound silently.
        memory_mib {
          min = 57344
          max = 294912
        }

        # Selects the family by ratio (c~2, m~4, r~8 GiB/vCPU), which holds at every size --
        # absolute bounds would drift and could admit r-family at memory-optimized prices.
        memory_gib_per_vcpu {
          min = 3.5
          max = 4.5
        }

        # Keep selection on general-purpose x86 CPU hosts.
        cpu_manufacturers = ["intel", "amd"]
        # Previous generations are materially slower and make benchmarks depend on which
        # family a task landed on. Widen only if capacity errors appear.
        instance_generations  = ["current"]
        burstable_performance = "excluded"

        # CPU-only: never place these tasks on accelerated (GPU) instances.
        accelerator_count {
          max = 0
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_cpu_capacity_provider" })

  # Only the permission grants need an explicit edge -- no attribute reference reaches them,
  # and ECS validates the role at creation. Roles and profile are already ordered by the
  # infrastructure_role_arn / ec2_instance_profile_arn references above.
  depends_on = [
    aws_iam_role_policy_attachment.executor_cpu_infrastructure_managed_instances,
    aws_iam_role_policy.executor_cpu_infrastructure_pass_instance_role,
    aws_iam_role_policy_attachment.executor_cpu_instance_managed_instances,
  ]
}

resource "aws_ecs_task_definition" "default_executor_managed" {
  family                   = "launch_system_default_executor_managed_task_family"
  network_mode             = local.executor_base_config.network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["MANAGED_INSTANCES"]
  execution_role_arn       = local.executor_base_config.default_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.default_executor_image_url
      environment = [
        {
          name  = "EXECUTOR_NAME"
          value = "python_3_12_compiler"
        }
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_default_executor"
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

resource "aws_ecs_task_definition" "inait_executor_managed" {
  family                   = "launch_system_inait_executor_managed_task_family"
  network_mode             = local.executor_base_config.network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["MANAGED_INSTANCES"]
  execution_role_arn       = local.executor_base_config.inait_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.default_executor_image_url
      environment = [
        {
          name  = "EXECUTOR_NAME"
          value = "python_3_12_inait"
        }
      ]
      secrets = [
        {
          name      = "GITHUB_DEPLOY_KEY_B64"
          valueFrom = "${var.secrets_arn}:GITHUB_DEPLOY_KEY_B64__inait::"
        },
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_inait_executor"
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

resource "aws_ecs_task_definition" "python_3_12_openmpi5_neuron9_neurodamus_executor_managed" {
  family                   = "launch_system_python_3_12_openmpi5_neuron9_neurodamus_executor_managed_task_family"
  network_mode             = local.executor_base_config.network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["MANAGED_INSTANCES"]
  execution_role_arn       = local.executor_base_config.default_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_container_base, {
      image = var.python_3_12_openmpi5_neuron9_neurodamus_executor_image_url
      environment = [
        {
          name  = "EXECUTOR_NAME"
          value = "python_3_12_openmpi5_neuron9_neurodamus"
        }
      ]
      logConfiguration = merge(local.executor_container_base.logConfiguration, {
        options = merge(local.executor_container_base.logConfiguration.options, {
          awslogs-stream-prefix = "launch_system_python_3_12_openmpi5_neuron9_neurodamus_executor"
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
