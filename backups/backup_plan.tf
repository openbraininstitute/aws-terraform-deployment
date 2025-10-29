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
          "elasticfilesystem:DescribeBackupPolicy"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "backup_role_managed_s3_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup_role_service_linked_backup" {
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSBackupServiceLinkedRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup_role_service_backup" {
  policy_arn = "arn:aws:iam::aws:policy/aws-service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

resource "aws_iam_role_policy_attachment" "backup_role_managed_s3_policy_restore" {
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  role       = aws_iam_role.backup_role.name
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

