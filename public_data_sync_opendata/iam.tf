resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_s3_policy" {
  name = "datasync-s3-policy"
  role = aws_iam_role.datasync_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.entitycore_internal_bucket}",
          "arn:aws:s3:::${var.entitycore_internal_bucket}/*",
          "arn:aws:s3:::${var.opendata_bucket}",
          "arn:aws:s3:::${var.opendata_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "cross_account_datasync_s3_role" {
  count = var.datasync_target_account == "" ? 0 : 1
  name  = "cross_account-datasync-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "cross_account_datasync_s3_policy" {
  count = var.datasync_target_account == "" ? 0 : 1
  name  = "datasync-s3-policy"
  role  = aws_iam_role.cross_account_datasync_s3_role[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.destination_entitycore_internal_bucket}",
          "arn:aws:s3:::${var.destination_entitycore_internal_bucket}/*",
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = var.datasync_target_account
          }
        }
      },
    ]
  })
}

