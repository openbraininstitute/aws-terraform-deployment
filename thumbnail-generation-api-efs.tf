
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