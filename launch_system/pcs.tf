locals {
  sudo_users = [
    { username = "gianluca.ficarelli", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDTQQu/jmTIhy7MjfoOlW6pqgjKpUa4r86UKlME7Tu0/l46xcmvnu64SvE99rLNUolNXdbv7PcnW/yzZpQery4ZCUtAzHLpPZQomu5v3AGa60JGXHRqtKu6ogv83VLgbsoEOPW50+WeBxJJYdrHq6kwc4AwFHlG1L8OsAj/b41HH530nAH7ytFcd8Z5JbUeXbvvT4Eouu+BUuSxvdq5Heq4G4OoYTLc9k+Eby4rjzTv1y5cn6nEmkX/fxhEs6ac+QIyyx1DyUD4LuSRvnpmUrSDcpVtHu61vJzTktVqbylU7J5GcBV5RDoAoOm/WnS3thNbWa3Y//x57OVgUCYd9JLM83zLbanaVPGwIoO77uWfmarKOnmLC7ycdr1B9ZPtZog0HyOh7qT7zXe4PCos3BVEUkQbOfXtXpU9pfJ8ce6LG6T+CUdkc8BHBlxVitsT2m+0kQr9LbilBJcw1sWyHMv5N984q9TQfz3IuX1sMtnVMEVe45TNT6M7goBJqdJsaatiunN7B19EVw1mtvQ58wOhHuA9GBIFWbQ5KJb1vK/JXsyjeE1CCa2oKoIAJOJgxwPnmvjGBnuIiP61b+fRo8UVfwXW+KdD1drgoC4y2D8NfdfvPip/atFnPKciWL9NK6Ur1CXNHilrDeKVTG4T2Pk1/iE0FdCTblmvoCO7No92VQ== gianluca.ficarelli@epfl.ch" },
    { username = "eleftherios.zisis", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1at36VDXWXddTNr0mhC2BUOztxUiSbDj1Bz/GRvLlid1D71MP+4e/RMv8553L7B2ovGymcJtWM7vfrP728lMr8F9zXU599qmdN+VcP+1xvpu5LPKUGopwKHDXbiZAGuKVqk3xRNmTpa54/wVXZsv5Pakyiu1lnqQkLaVFBcLjDZG98fN5O4vJ3nP8wnc3UVVrNg57mAErgHmnFe6K+IBRor/lZ27ffiDylzrwuFdKoQ91+LIOwQkrz49vKgvnvpy4QNtM7zWGzs/kQh2417LOCA/SkIyZl8i5M8ca663E6jeQekP6N+BxJkFyHaQzseQn/ptA/U/mLDG8E3SR/SbHfz28KMPA3Nv5kcC2Lh9AaWO4PFmmBbP5MS8WAQ02bKhI3dvskCm9HoZhpsh5SvMW9YhoFumuTOTpDXLq+4j9UI2niaiyxIuaZ+RmhJLEHiAnMLeg6bjpYG4Hbon99+fANF6DloxEqDQRl4j3+KZZzuY2FIL3U/D6SluamhqPpiyMgBLcZaeGqbhTTPPAeppBIJ78j4rq01cvQ+MTBTZL2l1GD8ZvbKkuCC2nxrz+xni2+VTO7VmjH59tks/21lRvsHqJi+OXC8atrw/uyU9wwkIbKsWwgt/FRXKtpz1dGVVuA4evPQcsnuuapfMUbcnWh4gp0B64NrVnww5JXZDVIw== eleftherios.zisis@openbraininstitute.org" },
    { username = "daniel.fernandez", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDnwCEkde+9uNQJ+sUPJwuCGbCQM1NFa5T0uPZNbQFTe1cw3XhW8X+HZg9em5xdX6NrT+R3gHTMvpqhLepmZzcWNpautY7qGG833i/gKO2VrTWf/Vd0aRefvc9ssWChWKWxnJu0IGnOJF7gSA27MMWvFHjIoYzPG0UVmfE+Nr1OYLMjpYEsxqj+bby44xD7ii7/hVJXp1reuRjOiSK+AosO1GNIkXcw7CQJy1gQ9VAc3qpKwv5uqBTlvKG8olL42U0Ndy61slyQrbJm3GVFIQFd4aIpYjEGlY+B1jhY+wvf8RxxjCqpJ8bz+yG+/QPzGEZeaDNYsOTxWIJRVSm9voLf danielfr@aur" },
    { username = "dries.verachtert", public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCw84Bv2npIvI5l9F8KeHPbdxPhykNduYetKMzeFT6BlEN7GKeDsgP5hHjf54aYugYovEgPO6fVf9L+NVHh8NaXgOSnhXjI7r4Iz4hDkOIxHdDHk0VHXZ3aaKA3XhZteJtKXfez1PMFon/AOXSEZuou/kpyFYZdsGKpX1V6RcF8f3Xd1HmIDrFQ4i136RJZzWMgjZAdFEqLdQRk1uiN1MvsHOnCAyMBvgid7gYvmgJIJNLFlh6yQlketZDEnQuHsPO+q43GeakWQ4CF7nfJyds1PD8jjsI/Nhk8ZWDj4A5v1ULVdNqYMcVslC87PdhsuPEw+RA8zAquEq7TGZjmJqzPE9OEq0iD+sj8qq7ziPStp+JNHJdDaSeO3g08SeQiklFvvcQv5rNkh+uNKeln2lXPOgrNV8oajpYsomNKif/ORz1t9tUKbsIiWXeNnJyJrsDZlkll8xEJtbNJY2PDL47KdAdADEZZjOvNAo3L2jWDmA/swRBnZRX9yYaJ7zxmFuFpw4/KFpUhXH5kbckZ+BfjENuRdm/PUDtyyeYICpL6AFaGzMF91b2CGftfHI4Nq7D2Xf1yQcEwP4ZHymDwlAu+H247WGprYD71bCbKYDHGzIDgG8f4jL2PdbwuNZ0fIP42K334IfFRpfK0fhJ8kSkr0xT4Sdg8NeNHba6Vcg+uiQ== Dries Verachtert - mac" },
    { username = "erik.heeren", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICCwlGHR/vz8esSOTMtXT0qnO7zg+kjPJYicxjyryO3h heeren@bbd-fsczyl3" },
    { username = "mgevaert", public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBCRTRSpJMLRRk0GuIcQ/OU5fGwgX0YhIMsy/sSgdzQc gevaert@theend" },
  ]
}

resource "awscc_pcs_cluster" "cluster" {
  name = "PCS-cluster"
  networking = {
    network_type       = "IPV4"
    security_group_ids = [aws_security_group.pcs.id]
    subnet_ids         = [aws_subnet.pcs.id]
  }
  # see available versions here:
  # https://docs.aws.amazon.com/pcs/latest/userguide/slurm-versions.html
  # note that changes to the version may require changes to the slurm `url`
  # and the service if the slrmREST API has changed
  scheduler = {
    type    = "SLURM"
    version = "25.05"
  }
  size = "SMALL"
  slurm_configuration = {
    accounting = {
      default_purge_time_in_days = 60
      mode                       = "STANDARD"
    }
    scale_down_idle_time_in_seconds = 600
    slurm_custom_settings = [
      {
        parameter_name  = "SelectTypeParameters"
        parameter_value = "CR_CPU_Memory"
      },
    ]
    slurm_rest = {
      mode = "STANDARD"
    }
  }
  tags = {
    SBO_Billing = "pcs-hpc"
  }
}

resource "aws_launch_template" "pcs_launch_template" {
  name                    = "pcs_launch_template"
  description             = "PCS Launch Template"
  disable_api_stop        = false
  disable_api_termination = false

  image_id = var.pcs_ami

  user_data = base64encode(templatefile("${path.module}/cloud-init.cfg", {
    fsx_dns_name               = aws_fsx_lustre_file_system.pcs_luster.dns_name
    fsx_mount_name             = aws_fsx_lustre_file_system.pcs_luster.mount_name
    publicdata_efs_id          = var.public_launch_data_efs_id
    opendata_access_point_id   = var.open_public_data_access_point_id
    publicdata_access_point_id = var.internal_public_data_access_point_id
    region                     = var.aws_region
    sudo_users                 = local.sudo_users
  }))

  vpc_security_group_ids = [
    aws_security_group.pcs.id,
  ]

  metadata_options {
    http_tokens = "required"
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "pcs-cluster-node",
      SBO_Billing = "pcs-hpc:parallelcluster"
    }
  }

  tags = {
    Name        = "base-pcs-cluster",
    SBO_Billing = "pcs-hpc:parallelcluster"
  }
}

resource "aws_placement_group" "efa" {
  name     = "efa-cluster"
  strategy = "cluster"
}

resource "aws_launch_template" "pcs_launch_template_efa" {
  name                    = "pcs_launch_template_efa"
  description             = "PCS Launch Template with EFA"
  disable_api_stop        = false
  disable_api_termination = false

  image_id = var.pcs_ami

  user_data = base64encode(templatefile("${path.module}/cloud-init.cfg", {
    fsx_dns_name               = aws_fsx_lustre_file_system.pcs_luster.dns_name
    fsx_mount_name             = aws_fsx_lustre_file_system.pcs_luster.mount_name
    publicdata_efs_id          = var.public_launch_data_efs_id
    opendata_access_point_id   = var.open_public_data_access_point_id
    publicdata_access_point_id = var.internal_public_data_access_point_id
    region                     = var.aws_region
    sudo_users                 = local.sudo_users
  }))

  network_interfaces {
    device_index          = 0
    interface_type        = "efa"
    security_groups       = [aws_security_group.pcs.id]
    delete_on_termination = true
  }

  metadata_options {
    http_tokens = "required"
  }

  placement {
    group_name = aws_placement_group.efa.name
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "pcs-cluster-node",
      SBO_Billing = "pcs-hpc:parallelcluster"
    }
  }

  tags = {
    Name        = "base-pcs-cluster",
    SBO_Billing = "pcs-hpc:parallelcluster"
  }
}

resource "awscc_pcs_compute_node_group" "pcs_nodegroup_small" {
  name       = "cluster-nodegroup-small"
  ami_id     = aws_launch_template.pcs_launch_template.image_id
  cluster_id = awscc_pcs_cluster.cluster.cluster_id

  custom_launch_template = {
    template_id = aws_launch_template.pcs_launch_template.id
    version     = aws_launch_template.pcs_launch_template.latest_version
  }

  iam_instance_profile_arn = aws_iam_instance_profile.pcs_profile.arn

  instance_configs = [
    {
      instance_type = "t3a.xlarge"
    },
  ]

  purchase_option = "ONDEMAND"

  scaling_configuration = {
    min_instance_count = 0
    max_instance_count = 4
  }

  slurm_configuration = {
    slurm_custom_settings = [
      {
        parameter_name  = "MemSpecLimit"
        parameter_value = 750
      },
    ]
  }

  subnet_ids = [aws_subnet.pcs.id]
  tags       = { SBO_Billing = "pcs-hpc" }
}

resource "awscc_pcs_queue" "pcs_queue_small" {
  cluster_id = awscc_pcs_cluster.cluster.cluster_id
  compute_node_group_configurations = [
    {
      compute_node_group_id = awscc_pcs_compute_node_group.pcs_nodegroup_small.compute_node_group_id
    },
  ]
  name = "pcs-queue-small"
  tags = { SBO_Billing = "pcs-hpc" }

  lifecycle {
    replace_triggered_by = [awscc_pcs_compute_node_group.pcs_nodegroup_small]
  }
}

resource "awscc_pcs_compute_node_group" "pcs_nodegroup_large" {
  name       = "cluster-nodegroup-large"
  ami_id     = aws_launch_template.pcs_launch_template.image_id
  cluster_id = awscc_pcs_cluster.cluster.cluster_id

  custom_launch_template = {
    template_id = (
      var.pcs_large_enable_efa ?
      aws_launch_template.pcs_launch_template_efa.id :
      aws_launch_template.pcs_launch_template.id
    )
    version = (
      var.pcs_large_enable_efa ?
      aws_launch_template.pcs_launch_template_efa.latest_version :
      aws_launch_template.pcs_launch_template.latest_version
    )
  }

  iam_instance_profile_arn = aws_iam_instance_profile.pcs_profile.arn

  instance_configs = [
    {
      instance_type = var.pcs_large_instance_type
    },
  ]

  purchase_option = "ONDEMAND"

  scaling_configuration = {
    min_instance_count = 0
    max_instance_count = var.pcs_large_nodes_max_instance_count
  }

  slurm_configuration = {
    slurm_custom_settings = [
      {
        parameter_name  = "MemSpecLimit"
        parameter_value = 750
      },
    ]
  }

  subnet_ids = [aws_subnet.pcs.id]

  tags = { SBO_Billing = "pcs-hpc" }
}

resource "awscc_pcs_queue" "pcs_queue_large" {
  cluster_id = awscc_pcs_cluster.cluster.cluster_id
  compute_node_group_configurations = [
    {
      compute_node_group_id = awscc_pcs_compute_node_group.pcs_nodegroup_large.compute_node_group_id
    },
  ]
  name = "pcs-queue-large"
  tags = { SBO_Billing = "pcs-hpc" }

  lifecycle {
    replace_triggered_by = [awscc_pcs_compute_node_group.pcs_nodegroup_large]
  }
}

locals {
  large_fallback_map = { for i, v in var.pcs_large_alternate_node_types : "alt${i}" => v }
}

resource "awscc_pcs_compute_node_group" "pcs_ng_large_fallback" {
  for_each = local.large_fallback_map

  name       = "cluster-ng-large-${each.key}"
  ami_id     = aws_launch_template.pcs_launch_template.image_id
  cluster_id = awscc_pcs_cluster.cluster.cluster_id

  custom_launch_template = {
    template_id = aws_launch_template.pcs_launch_template_efa.id
    version     = aws_launch_template.pcs_launch_template_efa.latest_version
  }

  iam_instance_profile_arn = aws_iam_instance_profile.pcs_profile.arn

  instance_configs = [
    { instance_type = each.value }
  ]

  purchase_option = "ONDEMAND"

  slurm_configuration = {
    slurm_custom_settings = [
      {
        parameter_name  = "MemSpecLimit"
        parameter_value = 750
      },
    ]
  }

  scaling_configuration = {
    min_instance_count = 0
    max_instance_count = 1
  }

  subnet_ids = [aws_subnet.pcs.id]

  tags = { SBO_Billing = "pcs-hpc" }
}

resource "awscc_pcs_queue" "pcs_queue_large_fallback" {
  for_each = local.large_fallback_map

  cluster_id = awscc_pcs_cluster.cluster.cluster_id
  compute_node_group_configurations = [
    {
      compute_node_group_id = awscc_pcs_compute_node_group.pcs_ng_large_fallback[each.key].compute_node_group_id
    },
  ]
  name = "pcs-q-large-${each.key}"
  tags = { SBO_Billing = "pcs-hpc" }

  lifecycle {
    replace_triggered_by = [awscc_pcs_compute_node_group.pcs_ng_large_fallback[each.key]]
  }
}

resource "aws_s3_bucket" "pcs_fsx_data" {
  bucket = var.pcs_fsx_scratch_s3_bucket_name
  tags   = { SBO_Billing = "pcs-hpc" }
}

resource "aws_s3_bucket_policy" "deny_insecure_transport" {
  bucket = aws_s3_bucket.pcs_fsx_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.pcs_fsx_data.arn,
          "${aws_s3_bucket.pcs_fsx_data.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_fsx_lustre_file_system" "pcs_luster" {
  storage_capacity            = 1200
  subnet_ids                  = [aws_subnet.pcs.id]
  deployment_type             = "PERSISTENT_2"
  storage_type                = "SSD"
  per_unit_storage_throughput = 125
  data_compression_type       = "LZ4"

  security_group_ids = [aws_security_group.pcs.id]
  tags               = { SBO_Billing = "pcs-hpc" }
}

resource "aws_fsx_data_repository_association" "pcs_s3" {
  file_system_id       = aws_fsx_lustre_file_system.pcs_luster.id
  data_repository_path = "s3://${aws_s3_bucket.pcs_fsx_data.id}/pcs_lustre/"
  file_system_path     = "/"

  s3 {
    auto_export_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }

    auto_import_policy {
      events = ["NEW", "CHANGED", "DELETED"]
    }
  }

  imported_file_chunk_size = 1024
  tags                     = { SBO_Billing = "hpc" }

  timeouts {
    create = "20m"
    delete = "20m"
  }
}

resource "aws_iam_role" "fsx_s3" {
  name = "fsx-s3-access"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "fsx.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "fsx_s3" {
  name = "fsx-s3-policy"
  role = aws_iam_role.fsx_s3.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucket"
      ]
      Resource = [
        aws_s3_bucket.pcs_fsx_data.arn,
        "${aws_s3_bucket.pcs_fsx_data.arn}/*"
      ]
    }]
  })
}

resource "aws_iam_role" "pcs_role" {
  # the webui claims this needs:
  # `The IAM role associated with the instance profile must either have AWSPCS as the role name prefix or contain /aws-pcs/ in the role path`
  name_prefix = "AWSPCS-pcs_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "pcs_policy" {
  name = "pcs-register-policy"
  role = aws_iam_role.pcs_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "pcs:RegisterComputeNodeGroupInstance"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_instance_profile" "pcs_profile" {
  name = "pcs-compute-node-profile"
  role = aws_iam_role.pcs_role.name
}
