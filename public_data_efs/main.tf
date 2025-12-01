resource "aws_efs_file_system" "public_launch_data" {
  creation_token = "public-launch-data"

  encrypted = false

  tags = {
    Name = "public-launch-data"
  }

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
}

resource "aws_efs_mount_target" "public_launch_data" {
  count           = length(var.access_point_subnet_ids)
  file_system_id  = aws_efs_file_system.public_launch_data.id
  subnet_id       = var.access_point_subnet_ids[count.index]
  security_groups = [aws_security_group.public_launch_efs.id]
}

resource "aws_security_group" "public_launch_efs" {
  name        = "public_launch_data-sg"
  description = "Security group for public launch data EFS mount targets"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_egress_rule" "datasync_nfs_access" {
  security_group_id = aws_security_group.public_launch_efs.id
  description       = "Allow NFS traffic from VPC"
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "public_launch_nfs_access" {
  security_group_id = aws_security_group.public_launch_efs.id
  description       = "Allow NFS traffic from VPC"
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
}

resource "aws_efs_access_point" "internal_public_data_readonly" {
  file_system_id = aws_efs_file_system.public_launch_data.id

  root_directory {
    path = var.internal_public_data_mountpath
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "555"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name = "internal-public-readonly"
  }
}

resource "aws_efs_access_point" "open_public_data_readonly" {
  file_system_id = aws_efs_file_system.public_launch_data.id

  root_directory {
    path = var.open_data_mountpath
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "555"
    }
  }

  posix_user {
    gid = 1000
    uid = 1000
  }

  tags = {
    Name = "open-public-readonly"
  }
}
