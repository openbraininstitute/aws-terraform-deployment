locals {
  bucket_name      = "obi-kiro-amazon-q-user-stats-${var.account_id}-${var.aws_region}"
  log_resource_arn = "${aws_s3_bucket.q_user_stats.arn}/*"
  account_id       = var.account_id
  q_source_arn     = "arn:aws:q:*:${var.account_id}:*"
}

resource "aws_s3_bucket" "q_user_stats" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    SBO_Billing = "kiro_amazon_q_user_stats"
  }
}

resource "aws_s3_bucket_public_access_block" "q_user_stats" {
  bucket = aws_s3_bucket.q_user_stats.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "q_user_stats" {
  bucket = aws_s3_bucket.q_user_stats.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "q_user_stats" {
  bucket = aws_s3_bucket.q_user_stats.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

data "aws_iam_policy_document" "q_logs_bucket_policy" {
  statement {
    sid    = "AllowQDeveloperOrKiroToWriteLogs"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["q.amazonaws.com"]
    }

    actions = [
      "s3:PutObject"
    ]

    resources = [
      local.log_resource_arn
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [local.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = [local.q_source_arn]
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "q_user_stats" {
  bucket = aws_s3_bucket.q_user_stats.id

  rule {
    id     = "expire-old-objects"
    status = "Enabled"

    expiration {
      days = 31
    }
  }
}

resource "aws_s3_bucket_policy" "q_user_stats" {
  bucket = aws_s3_bucket.q_user_stats.id
  policy = data.aws_iam_policy_document.q_logs_bucket_policy.json

  depends_on = [aws_s3_bucket_public_access_block.q_user_stats]
}
