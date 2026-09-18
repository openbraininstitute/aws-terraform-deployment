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

resource "aws_vpc_security_group_ingress_rule" "s3files_nfs_from_executor_cpu_instance" {
  security_group_id            = aws_security_group.s3files_private_data.id
  description                  = "Allow NFS from executor CPU managed instances"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.executor_cpu_instance.id
}

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

      # Attribute-based selection: describe the resources needed and let ECS Managed
      # Instances choose a suitable instance type. The vCPU/memory range fits the largest
      # supported executor task (16 vCPU / 120 GiB) and allows bin-packing multiple tasks.
      instance_requirements {
        vcpu_count {
          min = 32
          max = 64
        }

        memory_mib {
          min = 131072
          max = 262144
        }

        # Keep selection on general-purpose x86 CPU hosts.
        cpu_manufacturers = ["intel", "amd"]
        # TODO: revisit whether restricting to ["current"] gives materially better
        # per-core performance for executor workloads, at the cost of a smaller pool.
        instance_generations  = ["current", "previous"]
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
