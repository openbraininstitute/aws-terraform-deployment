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

# No S3 Files ingress rule is needed for this security group. Tested in sandbox-nse: the NFS
# mount for an S3 Files volume originates from the TASK's branch ENI, so it is governed by the
# task security group (see `s3files_nfs_from_executor` in s3files.tf), not by the instance
# security group carried on the trunk ENI. Running the same task definition with a task security
# group lacking that ingress fails with `mount.nfs4: Connection timed out`, and succeeds with the
# executor task security group. This matches the documented split: image pulls, secrets, logs and
# env files use the instance's primary ENI, while application traffic uses the task ENI.

resource "aws_ecs_capacity_provider" "executor_cpu" {
  name    = "launch_system_executor_cpu"
  cluster = aws_ecs_cluster.executor.name

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.executor_cpu_infrastructure.arn
    propagate_tags          = "CAPACITY_PROVIDER"

    # Replace instances that fail their EC2/ECS health checks instead of leaving them in the
    # pool. Pinned rather than inherited: the provider treats this as computed, so the default
    # is whatever the ECS API currently does and could change without a diff here. It matters
    # more than usual because scale_in_after keeps empty instances alive for a long time, so an
    # unhealthy host would otherwise keep attracting placements.
    #
    # Tradeoff: repair terminates the instance, so tasks running on it are killed. The
    # orchestrator already retries capacity/start failures, and executors are re-runnable.
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
      # BASIC is the ECS Managed Instances default: 5-minute EC2 metrics, no extra charge.
      # DETAILED adds paid 1-minute metrics per instance, which is not worth it here: executor
      # scheduling and task-level utilization are observed through ECS/CloudWatch task metrics,
      # not host metrics. Raise to DETAILED temporarily if host-level 1-minute resolution is
      # needed to debug instance sizing or bin-packing.
      monitoring = "BASIC"

      network_configuration {
        subnets         = local.executor_untrusted_subnet_ids
        security_groups = [aws_security_group.executor_cpu_instance.id]
      }

      # Shared by container images, writable layers, and task scratch data. This replaces
      # per-task Fargate ephemeral storage for executors running on managed instances.
      storage_configuration {
        storage_size_gib = 200
      }

      # Attribute-based selection: describe the resources needed and let ECS Managed Instances
      # choose a suitable instance type.
      #
      # The floor is 16 vCPU purely for cost: it is the smallest size satisfying the ratio below,
      # ECS automatically selects a larger type when a single task does not fit, and a 32 vCPU
      # floor would double the hourly rate to serve executor tasks that are 1-2 vCPU by default
      # (see var.executor_task_size).
      #
      # Task density is NOT limited by ENIs here. ECS Managed Instances attaches a trunk ENI as
      # the instance's primary interface by default and gives each task a branch ENI on it, so
      # the classic "one instance ENI per task" ceiling does not apply and the awsvpcTrunking
      # account setting is irrelevant. With trunking the documented limit is 60 tasks on a
      # 4xlarge (90 on 8xlarge, 120 on 12xlarge), far above what cpu/memory allows: verified in
      # sandbox-nse by running 12 concurrent 1 vCPU/2 GB tasks on a single m6a.4xlarge. cpu and
      # memory are therefore the binding constraints, which is what this block should be sized on.
      instance_requirements {
        vcpu_count {
          min = 16
          max = 64
        }

        # Absolute bounds derived from the vCPU range and the ratio band below, so the ratio is
        # what actually selects the family at every size: 16 vCPU x 3.5 = 56 GiB and
        # 64 vCPU x 4.5 = 288 GiB. Keeping these in step matters -- a floor of 64 GiB here would
        # silently override the 3.5 lower bound at 16 vCPU and make the effective minimum ratio
        # 4.0, so a future change to the ratio band would have no effect at the floor.
        memory_mib {
          min = 57344
          max = 294912
        }

        # "General purpose" is a ratio property, not an absolute one: c-family is ~2 GiB/vCPU,
        # m-family ~4, r-family ~8. Expressing it as a ratio holds at every instance size,
        # whereas absolute memory bounds shift which families qualify as vCPU changes and can
        # admit r-family hosts at memory-optimized prices for CPU-bound work.
        memory_gib_per_vcpu {
          min = 3.5
          max = 4.5
        }

        # Keep selection on general-purpose x86 CPU hosts.
        cpu_manufacturers = ["intel", "amd"]
        # Current generation only. Previous-generation families (m4/r4 era) have materially
        # slower cores, lower network and EBS throughput, and no NVMe, which works against the
        # cold-start and runtime goals of this capacity provider and makes benchmark results
        # depend on which family a given task happened to land on. The smaller pool is an
        # accepted tradeoff; widen it only if capacity errors show up in practice.
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

  # Only the permission grants need an explicit edge: ECS validates the infrastructure role
  # when the capacity provider is created, and an attachment or inline policy is not reachable
  # from any attribute reference here. The two roles and the instance profile are already
  # ordered by the infrastructure_role_arn and ec2_instance_profile_arn references above
  # (the instance role transitively, through the instance profile).
  depends_on = [
    aws_iam_role_policy_attachment.executor_cpu_infrastructure_managed_instances,
    aws_iam_role_policy.executor_cpu_infrastructure_pass_instance_role,
    aws_iam_role_policy_attachment.executor_cpu_instance_managed_instances,
  ]
}

# --- ECS Managed Instances task definitions -------------------------------------------------
# Parallel task definitions for the three non-GPU executors, compatible with the
# launch_system_executor_cpu ECS Managed Instances capacity provider defined above. They exist
# ALONGSIDE the Fargate task definitions in executor.tf so that jobs default to Fargate but can
# opt into Managed Instances per request via `placement_type: "ecs_managed_instances"` (see the
# matching Managed Instances entries in compute_cell_definitions.tf). They reuse the shared
# executor locals and are intentionally identical to their Fargate counterparts except for
# `requires_compatibilities`.
#
# THIS DUPLICATION IS DELIBERATELY TEMPORARY. It exists only so the two placements can be
# compared on the same workload, and it is not meant to be maintained: an executor image bump
# or a secrets change has to be applied here AND in executor.tf, and forgetting one silently
# gives the two placements different behavior.
#
# Removal condition -- exactly one of:
#   * Managed Instances wins: delete the Fargate task definitions in executor.tf and the
#     `fargate` entries in compute_cell_definitions.tf, then rename these to drop `_managed`.
#     Note that renaming a family orphans the orchestrator's derived per-project task
#     definitions (`{family}-{project_id}`), so plan that as its own change.
#   * Fargate wins: delete this file, the `ecs_managed_instances` entries in
#     compute_cell_definitions.tf, the executor_cpu capacity provider, and its registration in
#     executor.tf.
#
# TODO: if the comparison is inconclusive and the dual path has to stay, collapse both sets into
# one `for_each` over a variants map keyed by (executor, compatibility) instead of six near
# identical resources. That refactor must keep every `family` string byte-identical and use
# `moved` blocks (see moved.tf) so no task definition is orphaned.

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
