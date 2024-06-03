
# EFS creation
resource "aws_efs_file_system" "thumbnail_generation_api_efs_instance" {
  creation_token   = "thumbnail-generation-api-efs"
  performance_mode = "generalPurpose"
  encrypted        = false #tfsec:ignore:aws-efs-enable-at-rest-encryption

  tags = {
    Name        = "thumbnail-generation-api-efs"
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_efs_mount_target" "thumbnail_generation_api_efs_mount_target" {
  file_system_id  = aws_efs_file_system.thumbnail_generation_api_efs_instance.id
  subnet_id       = aws_subnet.thumbnail_generation_api.id
  security_groups = [aws_security_group.thumbnail_generation_api_sec_group.id]
}