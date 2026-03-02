locals {
  obp_s3_tags = merge(
    var.default_tags,
    {
      Nexus = "s3"
    }
  )
  openscience_s3_tags = merge(
    var.openscience,
    {
      Nexus = "s3"
    }
  )
}

##############################
## Bucket used by Nexus OBP ##
##############################

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_obp" {
  bucket = var.nexus_obp_bucket_name
  tags   = local.obp_s3_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "nexus_obp" {
  bucket = aws_s3_bucket.nexus_obp.id
  rule {
    id     = "DeleteOldMultipartUploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  rule {
    id     = "IntelligentTiering"
    status = "Enabled"
    filter {}

    transition {
      days          = 0         # Transition immediately upon creation
      storage_class = "GLACIER" # AKA Amazon S3 Glacier Flexible Retrieval
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nexus_obp" {
  bucket = aws_s3_bucket.nexus_obp.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_metric" "nexus_obp" {
  bucket = aws_s3_bucket.nexus_obp.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_policy" "nexus_obp" {
  bucket = aws_s3_bucket.nexus_obp.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.nexus_obp.arn,
          "${aws_s3_bucket.nexus_obp.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

######################################
## Bucket used by Nexus Openscience ##
######################################

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "nexus_openscience" {
  bucket = var.nexus_openscience_bucket_name
  tags   = local.openscience_s3_tags
}

resource "aws_s3_bucket_lifecycle_configuration" "nexus_openscience" {
  bucket = aws_s3_bucket.nexus_openscience.id
  rule {
    id     = "DeleteOldMultipartUploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
  rule {
    id     = "IntelligentTiering"
    status = "Enabled"
    filter {}

    transition {
      days          = 0         # Transition immediately upon creation
      storage_class = "GLACIER" # AKA Amazon S3 Glacier Flexible Retrieval
    }
  }
}

resource "aws_s3_bucket_public_access_block" "nexus_openscience" {
  bucket = aws_s3_bucket.nexus_openscience.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_metric" "nexus_openscience" {
  bucket = aws_s3_bucket.nexus_openscience.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_policy" "nexus_openscience" {
  bucket = aws_s3_bucket.nexus_openscience.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.nexus_openscience.arn,
          "${aws_s3_bucket.nexus_openscience.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}
