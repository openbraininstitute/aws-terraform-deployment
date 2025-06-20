resource "aws_efs_file_system" "small_scale_simulator_storage" {
  creation_token   = "small-scale-simulator-storage"
  performance_mode = "generalPurpose"
  encrypted        = false #tfsec:ignore:aws-efs-enable-at-rest-encryption

  tags = {
    Name = "small_scale_simulator_efs"
  }
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = {
    "subnet_primary_a_id" = aws_subnet.small_scale_simulator_primary_a.id
    "subnet_primary_b_id" = aws_subnet.small_scale_simulator_primary_b.id
  }

  file_system_id  = aws_efs_file_system.small_scale_simulator_storage.id
  subnet_id       = each.value
  security_groups = [aws_security_group.storage.id]
}
