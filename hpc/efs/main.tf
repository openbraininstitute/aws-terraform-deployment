# EFS storage to start with
resource "aws_efs_file_system" "compute_efs" {
  #ts:skip=AC_AWS_0097
  creation_token = "sbo-poc-compute-efs-token"
  encrypted      = false #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name     = "sbo-poc-compute-efs"
    HPC_Goal = "compute_cluster"
  }
}

# May require the use of https://docs.aws.amazon.com/efs/latest/ug/efs-mount-helper.html
# You only get one mount target per AV zone
resource "aws_efs_mount_target" "compute_efs" {
  file_system_id  = aws_efs_file_system.compute_efs.id
  count           = length(var.av_zone_suffixes)
  subnet_id       = var.compute_subnet_efs_ids[count.index]
  security_groups = [var.compute_efs_sg_id]
}

resource "aws_efs_backup_policy" "compute_backup_policy" {
  file_system_id = aws_efs_file_system.compute_efs.id

  backup_policy {
    status = "DISABLED"
  }
}
