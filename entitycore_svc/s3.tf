resource "aws_s3_bucket" "entitycore" {
  bucket = var.aws_s3_internal_bucket

  tags = {
    Name            = "entitycore-storage"
    obi_backup_plan = var.obi_backup_plan
  }
}

# Add CORS configuration to allow cross-origin access
resource "aws_s3_bucket_cors_configuration" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.s3_bucket_allowed_origins
    expose_headers  = ["ETag", "Content-Length", "Content-Type", "Last-Modified"]
    max_age_seconds = 3000
  }
}

# Disable versioning until enabled in entitycore
resource "aws_s3_bucket_versioning" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "prevent_delete" {
  bucket = aws_s3_bucket.entitycore.id

  policy = templatefile(var.source_datasync_role == "" ? "${path.module}/s3_bucket_policy_without_datasync_source.tftpl" : "${path.module}/s3_bucket_policy_with_datasync_source.tftpl", { "source_datasync_role" = var.source_datasync_role, "aws_s3_bucket_entitycore_arn" = aws_s3_bucket.entitycore.arn })
}

resource "aws_s3_bucket_metric" "entitycore-metrics" {
  bucket = aws_s3_bucket.entitycore.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_lifecycle_configuration" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  rule {
    id     = "remove-old-versions"
    status = "Enabled"
    filter {
      prefix = ""
    }
    noncurrent_version_expiration {
      noncurrent_days           = 90
      newer_noncurrent_versions = 3
    }
  }
}
