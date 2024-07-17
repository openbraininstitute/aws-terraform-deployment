locals {
  s3_tags        = merge(
    var.default_tags,
    {
      Nexus       = "s3"
    }
  )
}

###########
## First bucket used by the first instance of Nexus
###########

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_delta" {
  bucket = "nexus-delta-production"
  tags = local.s3_tags
}
resource "aws_s3_bucket_public_access_block" "nexus_delta" {
  bucket = aws_s3_bucket.nexus_delta.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_metric" "nexus_delta_metrics" {
  bucket = aws_s3_bucket.nexus_delta.id
  name   = "EntireBucket"
}

###########
## Second bucket used by the second instance of Nexus
###########

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus" {
  bucket = "nexus-bucket-production"
  tags = local.s3_tags
}

resource "aws_s3_bucket_public_access_block" "nexus" {
  bucket = aws_s3_bucket.nexus.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_metric" "nexus" {
  bucket = aws_s3_bucket.nexus.id
  name   = "EntireBucket"
}