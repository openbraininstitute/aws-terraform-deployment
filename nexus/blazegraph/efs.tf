# Blazegraph needs some storage for data
resource "aws_efs_file_system" "blazegraph" {
  #ts:skip=AC_AWS_0097
  creation_token         = var.blazegraph_efs_name
  availability_zone_name = "${data.aws_region.current.name}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption

  tags = {
    Name = var.blazegraph_efs_name
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.blazegraph.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_access_point" "blazegraph_config" {
  file_system_id = aws_efs_file_system.blazegraph.id
  root_directory {
    path = "/var/lib/blazegraph/config"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}

resource "aws_efs_mount_target" "efs_for_blazegraph" {
  file_system_id  = aws_efs_file_system.blazegraph.id
  subnet_id       = var.subnet_id
  security_groups = [var.subnet_security_group_id]
}

resource "aws_efs_access_point" "blazegraph" {
  file_system_id = aws_efs_file_system.blazegraph.id
  root_directory {
    path = var.efs_blazegraph_data_dir
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}