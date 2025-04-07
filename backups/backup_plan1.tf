resource "aws_backup_plan" "plan1" {
  name = "backup_plan1"

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

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "backup_role" {
  name = "backup_role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


resource "aws_backup_selection" "plan1_selection" {
  name         = "plan1_selection"
  plan_id      = aws_backup_plan.plan1.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "obi_backup_plan"
    value = "plan1"
  }
}