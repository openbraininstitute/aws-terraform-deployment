
### create efs volume to import keycloak.conf file and TLS certs
resource "aws_efs_file_system" "keycloakfs" {
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = "false" #tfsec:ignore:aws-efs-enable-at-rest-encryption
  tags = {
    Name        = "keycloak"
    SBO_Billing = "keycloak"
  }
}

### Create mount target for EFS for each subnet
resource "aws_efs_mount_target" "efs-mt" {
  count          = length(var.efs_mt_subnets)
  file_system_id = aws_efs_file_system.keycloakfs.id
  subnet_id      = var.efs_mt_subnets[count.index]
}

output "efs_arn" {
  value = aws_efs_file_system.keycloakfs.arn
}

### Create S3 bucket to upload certs and conf files
#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging tfsec:ignore:aws-s3-enable-versioning
resource "aws_s3_bucket" "core-services-keycloak" {
  bucket = "core-services-keycloak"
  tags = {
    Name        = "CS Keycloak"
    SBO_Billing = "keycloak"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.core-services-keycloak.id

  block_public_acls       = false #tfsec:ignore:aws-s3-block-public-acls
  block_public_policy     = false #tfsec:ignore:aws-s3-block-public-policy
  ignore_public_acls      = false #tfsec:ignore:aws-s3-ignore-public-acls
  restrict_public_buckets = false #tfsec:ignore:aws-s3-no-public-buckets
}


resource "aws_datasync_location_s3" "core-services-keycloak" {
  s3_bucket_arn = aws_s3_bucket.core-services-keycloak.arn
  subdirectory  = "/"
  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_datasync_location_efs" "datasync_destination_location" {
  ec2_config {
    security_group_arns = [aws_security_group.efs_sg.arn]
    subnet_arn          = var.datasync_subnet_arn
  }
  efs_file_system_arn = aws_efs_file_system.keycloakfs.arn
}

resource "aws_datasync_task" "keycloak_s3_to_efs" {
  destination_location_arn = aws_datasync_location_efs.datasync_destination_location.arn
  name                     = "keycloak_s3_to_efs"
  source_location_arn      = aws_datasync_location_s3.core-services-keycloak.arn
  options {
    bytes_per_second = -1
  }

  tags = {
    SBO_Billing = "keycloak"
  }
}



