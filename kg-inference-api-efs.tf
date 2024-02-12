
# EFS creation
resource "aws_efs_file_system" "kg_inference_api_efs_instance" {
  creation_token   = "kg-inference-api-efs"
  performance_mode = "generalPurpose"
  encrypted        = false #tfsec:ignore:aws-efs-enable-at-rest-encryption

  tags = {
    Name        = "kg-inference-api-efs"
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_efs_mount_target" "kg_inference_api_efs_mount_target" {
  file_system_id  = aws_efs_file_system.kg_inference_api_efs_instance.id
  subnet_id       = aws_subnet.kg_inference_api.id
  security_groups = [aws_security_group.kg_inference_api_sec_group.id]
}