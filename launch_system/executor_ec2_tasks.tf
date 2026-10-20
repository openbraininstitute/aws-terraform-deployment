locals {
  # Host paths prepared by user_data; container paths match existing app expectations.
  executor_internal_public_data_host_path = "/mnt/efs/internal_public_data"
  executor_open_public_data_host_path     = "/mnt/efs/open_data"

  # Host path only; container still sees ${local_store_prefix}/scratch/local-cache.
  executor_local_cache_volume_name = "local-cache"
  executor_local_cache_host_path   = "/var/lib/scratch/local-cache"
  executor_local_cache_mount_path  = "${var.local_store_prefix}/scratch/local-cache"

  executor_shared_cache_volume_name = "shared-cache"
  executor_shared_cache_efs_path    = "/cache/executor"
  executor_shared_cache_host_path   = "/mnt/efs/shared_cache"
  executor_shared_cache_mount_path  = "${var.local_store_prefix}/scratch/shared-cache"

  executor_ecr_registry = split("/", var.default_executor_image_url)[0]

  executor_ec2_container_base = merge(local.executor_container_base, {
    mountPoints = [
      {
        containerPath = "/data/aws_s3_internal/public"
        sourceVolume  = "public-internal-data"
        readOnly      = true
      },
      {
        containerPath = "/data/aws_s3_open"
        sourceVolume  = "public-open-data"
        readOnly      = true
      },
      {
        containerPath = local.executor_local_cache_mount_path
        sourceVolume  = local.executor_local_cache_volume_name
        readOnly      = false
      },
      {
        containerPath = local.executor_shared_cache_mount_path
        sourceVolume  = local.executor_shared_cache_volume_name
        readOnly      = false
      }
    ]
  })

  # Host networking: RunTask must omit networkConfiguration.
  executor_ec2_network_mode = "host"

  executor_ec2_volumes = [
    { name = "public-internal-data", host_path = local.executor_internal_public_data_host_path },
    { name = "public-open-data", host_path = local.executor_open_public_data_host_path },
    { name = local.executor_local_cache_volume_name, host_path = local.executor_local_cache_host_path },
    { name = local.executor_shared_cache_volume_name, host_path = local.executor_shared_cache_host_path },
  ]
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
  description = "Security group for launch system executor CPU instances"

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

resource "aws_ecs_task_definition" "default_executor_ec2" {
  family                   = "launch_system_default_executor_ec2_task_family"
  network_mode             = local.executor_ec2_network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["EC2"]
  execution_role_arn       = local.executor_base_config.default_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_ec2_container_base, {
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
    for_each = local.executor_ec2_volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}

resource "aws_ecs_task_definition" "inait_executor_ec2" {
  family                   = "launch_system_inait_executor_ec2_task_family"
  network_mode             = local.executor_ec2_network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["EC2"]
  execution_role_arn       = local.executor_base_config.inait_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_ec2_container_base, {
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
    for_each = local.executor_ec2_volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}

resource "aws_ecs_task_definition" "python_3_12_openmpi5_neuron9_neurodamus_executor_ec2" {
  family                   = "launch_system_python_3_12_openmpi5_neuron9_neurodamus_executor_ec2_task_family"
  network_mode             = local.executor_ec2_network_mode
  cpu                      = local.executor_base_config.cpu
  memory                   = local.executor_base_config.memory
  requires_compatibilities = ["EC2"]
  execution_role_arn       = local.executor_base_config.default_execution_role_arn
  task_role_arn            = local.executor_base_config.task_role_arn

  container_definitions = jsonencode([
    merge(local.executor_ec2_container_base, {
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
    for_each = local.executor_ec2_volumes
    content {
      name      = volume.value.name
      host_path = volume.value.host_path
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.executor,
  ]
}
