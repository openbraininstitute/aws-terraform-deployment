#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_ship" {
  bucket = "nexus-ship-production"

  tags = {
    SBO_Billing = "nexus_ship"
  }
}
resource "aws_s3_bucket_public_access_block" "nexus_ship" {
  bucket = aws_s3_bucket.nexus_ship.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.nexus_ship.id
  key    = "ship.conf"
  source = "${path.module}/ship.conf"
  etag   = filemd5("${path.module}/ship.conf")
}
