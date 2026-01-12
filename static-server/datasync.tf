resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync-s3-role-static"

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
          "arn:aws:s3:::${var.static_content_bucket_name}",
          "arn:aws:s3:::${var.static_content_bucket_name}/*",
          "arn:aws:s3:::${var.cell_static_content_bucket_name}",
          "arn:aws:s3:::${var.cell_static_content_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_datasync_location_s3" "static_content_bucket_location" {
  s3_bucket_arn = aws_s3_bucket.static_storage.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_location_s3" "cell_static_content_bucket_location" {
  s3_bucket_arn = aws_s3_bucket.cell_static_storage.arn
  subdirectory  = "/"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_task" "sync_static_content" {
  name = "sync-static-content-to-cell"

  source_location_arn      = aws_datasync_location_s3.static_content_bucket_location.arn
  destination_location_arn = aws_datasync_location_s3.cell_static_content_bucket_location.arn

  schedule {
    schedule_expression = "cron(0 7 ? * * *)"
  }
}
