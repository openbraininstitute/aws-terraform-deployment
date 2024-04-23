#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_delta" {
  bucket = "nexus-delta-production"

  tags = {
    SBO_Billing = "nexus_ship"
  }
}
resource "aws_s3_bucket_public_access_block" "nexus_delta" {
  bucket = aws_s3_bucket.nexus_delta.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}