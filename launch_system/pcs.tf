resource "awscc_pcs_cluster" "cluster" {
  name = "PCS-cluster"
  networking = {
    network_type       = "IPV4"
    security_group_ids = [aws_security_group.pcs.id]
    subnet_ids         = [aws_subnet.pcs.id]
  }
  scheduler = {
    type    = "SLURM"
    version = "25.05"
  }
  size = "SMALL"
  slurm_configuration = {
    accounting = {
      default_purge_time_in_days = -1
      mode                       = "STANDARD"
    }
    scale_down_idle_time_in_seconds = 600
    slurm_custom_settings = [
      {
        parameter_name  = "SelectTypeParameters"
        parameter_value = "CR_CPU"
      },
    ]
    slurm_rest = {
      mode = "STANDARD"
    }
  }
}

resource "aws_launch_template" "pcs_launch_template" {
  name                    = "pcs_launch_template"
  description             = "PCS Launch Template"
  disable_api_stop        = false
  disable_api_termination = false

  image_id = var.pcs_ami

  user_data = base64encode(templatefile("${path.module}/cloud-init.cfg", {
    fsx_dns_name   = aws_fsx_lustre_file_system.pcs_luster.dns_name
    fsx_mount_name = aws_fsx_lustre_file_system.pcs_luster.mount_name
    region         = var.aws_region
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
      Name = "pcs-cluster-node"
    }
  }

  tags = {
    Name = "base-pcs-cluster"
  }
}

resource "awscc_pcs_compute_node_group" "pcs_nodegroup" {
  name       = "cluster-nodegroup"
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
  subnet_ids = [aws_subnet.pcs.id]
  tags       = {}
}

resource "awscc_pcs_queue" "pcs_queue" {
  cluster_id = awscc_pcs_cluster.cluster.cluster_id
  compute_node_group_configurations = [
    {
      compute_node_group_id = awscc_pcs_compute_node_group.pcs_nodegroup.compute_node_group_id
    },
  ]
  name = "pcs-queue"
  tags = {}
}

resource "aws_s3_bucket" "pcs_fsx_data" {
  bucket = var.pcs_fsx_scratch_s3_bucket_name
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
