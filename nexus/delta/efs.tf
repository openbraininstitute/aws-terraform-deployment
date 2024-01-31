# place to put delta.conf
resource "aws_efs_file_system" "nexus_app_config" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-nexus-app-config"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "sbp-poc-nexus-app-config"
    SBO_Billing = "nexus_app"
  }
}

resource "aws_efs_backup_policy" "nexus_backup_policy" {
  file_system_id = aws_efs_file_system.nexus_app_config.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_nexus_app" {
  file_system_id  = aws_efs_file_system.nexus_app_config.id
  subnet_id       = var.subnet_id
  security_groups = [var.subnet_security_group_id]
}
