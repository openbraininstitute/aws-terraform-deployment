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

resource "aws_efs_mount_target" "mount_target" {
  count           = length(var.subnet_ids)
  file_system_id  = aws_efs_file_system.public_launch_data.id
  subnet_id       = var.subnet_ids[count.index]
  security_groups = [aws_security_group.public_launch_efs.id]
}

resource "aws_security_group" "public_launch_efs" {
  name        = "public_launch_data-sg"
  description = "Security group for public launch data EFS mount targets"
  vpc_id      = var.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "public_launch_nfs_access" {
  security_group_id = aws_security_group.efs_sg.id
  description       = "Allow NFS traffic from VPC"
  from_port         = 2049
  to_port           = 2049
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr
}
