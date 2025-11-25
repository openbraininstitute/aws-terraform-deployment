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
  name = "datasync_s3_policy"
  role = aws_iam_role.datasync_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSDataSyncS3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = [
          "arn:aws:s3:::${var.open_data_bucket}",
          "arn:aws:s3:::${var.entitycore_internal_bucket}"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = var.account_id
          }
        }
      },
      {
        Sid    = "AWSDataSyncS3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:GetObjectTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.open_data_bucket}/*",
          "arn:aws:s3:::${var.entitycore_internal_bucket}/*"
        ]
        Condition = {
          StringEquals = {
            "aws:ResourceAccount" = var.account_id
          }
        }
      }
    ]
  })
}

resource "aws_datasync_location_s3" "internal_source" {
  s3_bucket_arn = "arn:aws:s3:::${var.entitycore_internal_bucket}"
  subdirectory  = "/public"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_location_efs" "internal_destination" {
  efs_file_system_arn = aws_efs_file_system.public_launch_data.arn
  subdirectory        = "/data/aws_s3_internal/public"

  ec2_config {
    security_group_arns = [aws_security_group.public_launch_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${var.access_point_subnet_ids[0]}"
  }

  depends_on = [aws_efs_mount_target.public_launch_data]
}

resource "aws_datasync_location_efs" "opendata_destination" {
  efs_file_system_arn = aws_efs_file_system.public_launch_data.arn
  subdirectory        = "/data/aws_s3_open/"

  ec2_config {
    security_group_arns = [aws_security_group.public_launch_efs.arn]
    subnet_arn          = "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${var.access_point_subnet_ids[0]}"
  }

  depends_on = [aws_efs_mount_target.public_launch_data]
}

resource "aws_datasync_task" "internal_s3_to_efs" {
  destination_location_arn = aws_datasync_location_efs.internal_destination.arn
  source_location_arn      = aws_datasync_location_s3.internal_source.arn
  name                     = "s3-to-efs-sync"

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "INT_VALUE"
    gid                    = "INT_VALUE"
    posix_permissions      = "PRESERVE"
    preserve_devices       = "NONE"
    bytes_per_second       = -1 # unlimited
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }
}

# TODO add datasync source / destination / task for opendata once we know exactly which prefixes we want to sync
