resource "aws_efs_file_system" "model_cache_efs" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = false #tfsec:ignore:aws-efs-enable-at-rest-encryption

  tags = {
    Name = "bluenaas_efs"
  }
}

resource "aws_efs_mount_target" "mount_target" {
  for_each = {
    "subnet_a_id" = aws_subnet.bluenaas_ecs_a.id
    "subnet_b_id" = aws_subnet.bluenaas_ecs_b.id
  }

  file_system_id  = aws_efs_file_system.model_cache_efs.id
  subnet_id       = each.value
  security_groups = [aws_security_group.main_sg.id]
}
