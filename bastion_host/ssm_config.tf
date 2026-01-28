resource "aws_ssm_document" "user_specific_mapping" {
  for_each = { for user in local.all_users : user.username => user }

  name            = "SSM-UserMapping-${each.key}"
  document_type   = "Session"
  document_format = "JSON"

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document for user-specific mapping: ${each.key}"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = aws_s3_bucket.session_logs.id
      s3EncryptionEnabled         = true
      cloudWatchEncryptionEnabled = true
      kmsKeyId                    = aws_kms_key.cloudwatch_logs.arn
      runAsEnabled                = true
      runAsDefaultUser            = each.key
      idleSessionTimeout          = "20"
      maxSessionDuration          = "60"
      shellProfile = {
        linux = "cd /home/${each.key} && exec /bin/bash --login"
      }
    }
  })

  tags = {
    UserGroup    = each.value.group
    SudoAccess   = each.value.sudo ? "true" : "false"
    AllowedEmail = each.value.email
  }
}

resource "aws_s3_bucket" "session_logs" {
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_cloudwatch_log_group" "session_logs" {
  name              = "/aws/ssm/session-manager"
  retention_in_days = 365
  kms_key_id        = aws_kms_key.cloudwatch_logs.arn
}

resource "aws_s3_bucket_server_side_encryption_configuration" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "session_logs" {
  bucket = aws_s3_bucket.session_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.session_logs.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" : "AES256"
          }
        }
      },
      {
        Sid       = "DenyNonSSLRequests"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource  = "${aws_s3_bucket.session_logs.arn}/*"
        Condition = {
          Bool = {
            "aws:SecureTransport" : "false"
          }
        }
      }
    ]
  })
}
