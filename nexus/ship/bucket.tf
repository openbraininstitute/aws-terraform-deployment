#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_ship" {
  bucket = var.nexus_ship_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "nexus_ship" {
  bucket = aws_s3_bucket.nexus_ship.id
  rule {
    id     = "DeleteOldMultipartUploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
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

resource "aws_s3_bucket_metric" "nexus_ship_metrics" {
  bucket = aws_s3_bucket.nexus_ship.id
  name   = "EntireBucket"
}
