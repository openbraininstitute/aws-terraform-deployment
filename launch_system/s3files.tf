# S3 Files file system for private project data
# Allows ECS/Fargate tasks to mount per-project S3 prefixes as local filesystems
# without needing EFS + DataSync.

resource "aws_iam_role" "s3files_private_data" {
  name_prefix = "launch_system_s3files_"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowS3FilesAssumeRole"
      Effect    = "Allow"
      Principal = { Service = "elasticfilesystem.amazonaws.com" }
      Action    = "sts:AssumeRole"
      Condition = {
        StringEquals = { "aws:SourceAccount" = var.account_id }
        ArnLike      = { "aws:SourceArn" = "arn:aws:s3files:${var.aws_region}:${var.account_id}:file-system/*" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "s3files_private_data" {
  name = "s3files-private-data-access"
  role = aws_iam_role.s3files_private_data.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "S3BucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:ListBucketVersions",
        ]
        Resource = "arn:aws:s3:::${var.private_data_s3_bucket_name}"
        Condition = {
          StringEquals = { "aws:ResourceAccount" = var.account_id }
          StringLike   = { "s3:prefix" = ["${var.private_data_s3_prefix}*"] }
        }
      },
      {
        Sid    = "S3ObjectPermissions"
        Effect = "Allow"
        Action = [
          "s3:AbortMultipartUpload",
          "s3:DeleteObject*",
          "s3:GetObject*",
          "s3:List*",
          "s3:PutObject*",
        ]
        Resource = "arn:aws:s3:::${var.private_data_s3_bucket_name}/${var.private_data_s3_prefix}*"
        Condition = {
          StringEquals = { "aws:ResourceAccount" = var.account_id }
        }
      },
      {
        Sid    = "EventBridgeManage"
        Effect = "Allow"
        Action = [
          "events:DeleteRule",
          "events:DisableRule",
          "events:EnableRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
        ]
        Resource  = ["arn:aws:events:*:*:rule/DO-NOT-DELETE-S3-Files*"]
        Condition = { StringEquals = { "events:ManagedBy" = "elasticfilesystem.amazonaws.com" } }
      },
      {
        Sid    = "EventBridgeRead"
        Effect = "Allow"
        Action = [
          "events:DescribeRule",
          "events:ListRuleNamesByTarget",
          "events:ListRules",
          "events:ListTargetsByRule",
        ]
        Resource = ["arn:aws:events:*:*:rule/*"]
      }
    ]
  })
}

resource "aws_s3files_file_system" "private_data" {
  bucket   = "arn:aws:s3:::${var.private_data_s3_bucket_name}"
  prefix   = var.private_data_s3_prefix
  role_arn = aws_iam_role.s3files_private_data.arn

  tags = merge(var.tags, { Name = "launch-system-private-data" })
}

resource "aws_security_group" "s3files_private_data" {
  name_prefix = "launch_system_s3files_nfs_"
  vpc_id      = var.vpc_id
  description = "Allow NFS from executor tasks to S3 Files mount targets"

  tags = merge(var.tags, { Name = "launch_system_s3files_nfs" })
}

resource "aws_vpc_security_group_ingress_rule" "s3files_nfs_from_executor" {
  security_group_id            = aws_security_group.s3files_private_data.id
  description                  = "Allow NFS from executor tasks"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.executor.id
}

resource "aws_vpc_security_group_egress_rule" "s3files_allow_all" {
  security_group_id = aws_security_group.s3files_private_data.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
  description       = "Allow all outbound"
}

resource "aws_s3files_mount_target" "private_data_a" {
  file_system_id  = aws_s3files_file_system.private_data.id
  subnet_id       = aws_subnet.untrusted_a.id
  security_groups = [aws_security_group.s3files_private_data.id]
}

resource "aws_s3files_mount_target" "private_data_b" {
  file_system_id  = aws_s3files_file_system.private_data.id
  subnet_id       = aws_subnet.untrusted_b.id
  security_groups = [aws_security_group.s3files_private_data.id]
}

resource "aws_s3files_mount_target" "private_data_c" {
  file_system_id  = aws_s3files_file_system.private_data.id
  subnet_id       = aws_subnet.untrusted_c.id
  security_groups = [aws_security_group.s3files_private_data.id]
}

resource "aws_s3files_mount_target" "private_data_d" {
  file_system_id  = aws_s3files_file_system.private_data.id
  subnet_id       = aws_subnet.untrusted_d.id
  security_groups = [aws_security_group.s3files_private_data.id]
}
