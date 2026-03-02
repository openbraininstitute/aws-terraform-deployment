resource "aws_s3_bucket" "core_webapp" {
  count  = var.key == "main" ? 1 : 0
  bucket = var.s3_bucket_name

  tags = {
    Name        = "core-webapp-assets-${var.key}"
    SBO_Billing = "core_webapp"
  }
}

resource "aws_s3_bucket_cors_configuration" "core_webapp" {
  count  = var.key == "main" ? 1 : 0
  bucket = aws_s3_bucket.core_webapp[0].id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET", "HEAD"]
    allowed_origins = var.s3_bucket_allowed_origins
    expose_headers  = ["ETag", "Content-Length", "Content-Type", "Last-Modified", "Cache-Control"]
    max_age_seconds = 3600
  }
}

# Enable versioning for assets
resource "aws_s3_bucket_versioning" "core_webapp" {
  count  = var.key == "main" ? 1 : 0
  bucket = aws_s3_bucket.core_webapp[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "core_webapp" {
  count  = var.key == "main" ? 1 : 0
  bucket = aws_s3_bucket.core_webapp[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access initially (CloudFront will access via OAC)
resource "aws_s3_bucket_public_access_block" "core_webapp" {
  count  = var.key == "main" ? 1 : 0
  bucket = aws_s3_bucket.core_webapp[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


# S3 bucket policy for CloudFront OAC access
data "aws_iam_policy_document" "core_webapp_policy" {
  count = var.key == "main" ? 1 : 0
  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = ["s3:*"]
    resources = [
      aws_s3_bucket.core_webapp[0].arn,
      "${aws_s3_bucket.core_webapp[0].arn}/*"
    ]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
  statement {
    sid    = "AllowCloudFrontServicePrincipal"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "${aws_s3_bucket.core_webapp[0].arn}/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.core_webapp_cdn[0].arn]
    }
  }
  statement {
    sid    = "AllowGitHubActionsUploadUser"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::985539765147:user/github_actions_upload_user_core_web_app"]
    }
    actions = [
      "s3:ListBucket",
      "s3:PutObject",
      "s3:GetObject",
    ]
    resources = [
      "${aws_s3_bucket.core_webapp[0].arn}",
      "${aws_s3_bucket.core_webapp[0].arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "core_webapp_policy" {
  count  = var.key == "main" ? 1 : 0
  bucket = aws_s3_bucket.core_webapp[0].id
  policy = data.aws_iam_policy_document.core_webapp_policy[0].json

  depends_on = [aws_cloudfront_distribution.core_webapp_cdn[0]]
}
