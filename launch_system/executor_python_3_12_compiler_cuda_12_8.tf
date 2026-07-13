locals {
  # Prioritized fallbacks when g6e.4xlarge has no AZ capacity (common for L40S SKUs).
  # All types below provide >= 64 GiB RAM and 1 GPU.
  executor_gpu_instance_types = [
    # 16 vCPU / 64 GiB / 1x NVIDIA A10G (24 GB VRAM)
    "g5.4xlarge",
  ]
}

data "aws_iam_policy_document" "executor_gpu_infrastructure_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ecs.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "executor_gpu_infrastructure" {
  name               = "launch_system_executor_gpu_infrastructure"
  assume_role_policy = data.aws_iam_policy_document.executor_gpu_infrastructure_role_assume.json
}

resource "aws_iam_role_policy_attachment" "executor_gpu_infrastructure_managed_instances" {
  role       = aws_iam_role.executor_gpu_infrastructure.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInfrastructureRolePolicyForManagedInstances"
}

data "aws_iam_policy_document" "executor_gpu_infrastructure_pass_instance_role" {
  statement {
    sid    = "PassInstanceRoleToEC2"
    effect = "Allow"

    actions = ["iam:PassRole"]
    resources = [
      aws_iam_role.executor_gpu_instance.arn,
    ]

    condition {
      test     = "StringLike"
      variable = "iam:PassedToService"
      values   = ["ec2.*"]
    }
  }
}

resource "aws_iam_role_policy" "executor_gpu_infrastructure_pass_instance_role" {
  name   = "pass-instance-role"
  role   = aws_iam_role.executor_gpu_infrastructure.id
  policy = data.aws_iam_policy_document.executor_gpu_infrastructure_pass_instance_role.json
}

data "aws_iam_policy_document" "executor_gpu_instance_role_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "executor_gpu_instance" {
  name               = "launch_system_executor_gpu_instance"
  assume_role_policy = data.aws_iam_policy_document.executor_gpu_instance_role_assume.json
}

resource "aws_iam_role_policy_attachment" "executor_gpu_instance_managed_instances" {
  role       = aws_iam_role.executor_gpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECSInstanceRolePolicyForManagedInstances"
}

resource "aws_iam_role_policy_attachment" "executor_gpu_instance_ssm" {
  role       = aws_iam_role.executor_gpu_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "executor_gpu_instance" {
  name = "launch_system_executor_gpu_instance"
  role = aws_iam_role.executor_gpu_instance.name
}

resource "aws_security_group" "executor_gpu_instance" {
  name_prefix = "launch_system_executor_gpu"
  vpc_id      = var.vpc_id
  description = "Security group for launch system executor GPU ECS managed instances"

  tags = merge(var.tags, { Name = "launch_system_executor_gpu_instance" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_egress_rule" "executor_gpu_instance_allow_outgoing" {
  security_group_id = aws_security_group.executor_gpu_instance.id
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all egress for ECS GPU instances"
}

resource "aws_ecs_capacity_provider" "executor_gpu" {
  name    = "launch_system_executor_gpu"
  cluster = aws_ecs_cluster.executor.name

  managed_instances_provider {
    infrastructure_role_arn = aws_iam_role.executor_gpu_infrastructure.arn
    propagate_tags          = "CAPACITY_PROVIDER"

    infrastructure_optimization {
      # Mirrors the previous ASG instance_warmup_period (300s) before idle scale-in.
      scale_in_after = 300
    }

    instance_launch_template {
      ec2_instance_profile_arn = aws_iam_instance_profile.executor_gpu_instance.arn
      monitoring               = "DETAILED"

      network_configuration {
        subnets         = local.executor_untrusted_subnet_ids
        security_groups = [aws_security_group.executor_gpu_instance.id]
      }

      instance_requirements {
        allowed_instance_types = local.executor_gpu_instance_types

        vcpu_count {
          min = 8
          max = 16
        }

        memory_mib {
          min = 65536
          max = 131072
        }

        accelerator_types         = ["gpu"]
        accelerator_manufacturers = ["nvidia"]

        accelerator_count {
          min = 1
          max = 1
        }
      }
    }
  }

  tags = merge(var.tags, { Name = "launch_system_executor_gpu_capacity_provider" })

  depends_on = [
    aws_iam_role.executor_gpu_infrastructure,
    aws_iam_role_policy_attachment.executor_gpu_infrastructure_managed_instances,
    aws_iam_role_policy.executor_gpu_infrastructure_pass_instance_role,
    aws_iam_role.executor_gpu_instance,
    aws_iam_role_policy_attachment.executor_gpu_instance_managed_instances,
    aws_iam_instance_profile.executor_gpu_instance,
  ]
}

resource "aws_ecs_task_definition" "python_3_12_compiler_cuda_12_8_executor" {
  family                   = "launch_system_python_3_12_compiler_cuda_12_8_executor_task_family"
  network_mode             = "awsvpc"
  cpu                      = tostring(var.executor_task_size.cpu)
  memory                   = tostring(var.executor_task_size.memory)
  requires_compatibilities = ["MANAGED_INSTANCES"]
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
