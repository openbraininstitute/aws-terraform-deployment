resource "aws_efs_file_system" "delta_nginx" {
  #ts:skip=AC_AWS_0097
  creation_token         = var.nginx_efs_name
  availability_zone_name = "${data.aws_region.current.name}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name = var.nginx_efs_name
  }
}

resource "aws_efs_backup_policy" "nexus_backup_policy" {
  file_system_id = aws_efs_file_system.delta_nginx.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_nexus_app" {
  file_system_id  = aws_efs_file_system.delta_nginx.id
  subnet_id       = var.subnet_id
  security_groups = [var.subnet_security_group_id]
}

resource "aws_efs_access_point" "delta_config" {
  file_system_id = aws_efs_file_system.delta_nginx.id
  root_directory {
    path = "/etc/nginx"
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = "0777"
    }
  }
}