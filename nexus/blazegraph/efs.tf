# Blazegraph needs some storage for data
resource "aws_efs_file_system" "blazegraph" {
  #ts:skip=AC_AWS_0097
  creation_token         = "sbo-poc-blazegraph"
  availability_zone_name = "${var.aws_region}a"
  encrypted              = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "sbp-poc-blazegraph"
    SBO_Billing = "nexus"
  }
}

resource "aws_efs_backup_policy" "policy" {
  file_system_id = aws_efs_file_system.blazegraph.id

  backup_policy {
    status = "DISABLED"
  }
}

resource "aws_efs_mount_target" "efs_for_blazegraph" {
  file_system_id  = aws_efs_file_system.blazegraph.id
  subnet_id       = var.subnet_id
  security_groups = [var.subnet_security_group_id]
}