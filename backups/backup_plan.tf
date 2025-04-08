resource "aws_backup_plan" "obi_plan" {
  name = "obi_plan"

  rule {
    rule_name         = "daily-backup"
    target_vault_name = aws_backup_vault.obi_vault.name
    schedule          = "cron(0 3 * * ? *)" # Daily at 3:00 UTC
    lifecycle {
      delete_after = 14 # Days to retain backups
    }
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}


resource "aws_iam_role" "backup_role" {
  name = "backup_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy" "backup_role_policy" {
  name = "backup_role_policy"
  role = aws_iam_role.backup_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "tag:getResources",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ListTagsForResource",
          "rds:CreateDBSnapshot",
          "rds:DeleteDBSnapshot",
          "rds:CopyDBSnapshot",
          "rds:DescribeDBSnapshots",
          "rds:AddTagsToResource"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "s3:GetBucketNotification",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetBucketTagging",
          "s3:GetBucketVersioning",
          "s3:GetBucketPublicAccessBlock",
          "s3:GetBucketAcl",
          "s3:GetBucketPolicy",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:GetObjectTagging",
          "s3:GetObjectAcl",
          "s3:PutBucketNotification",
          "events:ListRules",
          "events:PutRule",
          "events:ListTargetsByRule"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "elasticfilesystem:DescribeFileSystems",
          "elasticfilesystem:DescribeBackupPolicy",
          "elasticfilesystem:Backup",
          "elasticfilesystem:DescribeTags"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}


resource "aws_backup_selection" "obi_plan_selection" {
  name         = "obi_plan_selection"
  plan_id      = aws_backup_plan.obi_plan.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "obi_backup_plan"
    value = "obi_plan"
  }
}