# Setup of the 'local' vault, which is within the AWS account.

resource "aws_backup_vault" "obi_vault" {
  name = "obi_vault"
  #kms_key_arn = aws_kms_key.local_key.arn
  tags = {
    Name = "obi_vault"
  }
}

resource "aws_sns_topic" "backups" {
  name = "backup-vault-events"
}

data "aws_iam_policy_document" "backups_sns_topic" {
  policy_id = "backups_sns_topic_policy"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.backups.arn,
    ]

    sid = "backups_sns_topic_policy"
  }
}

resource "aws_sns_topic_policy" "backups_sns_topic" {
  arn    = aws_sns_topic.backups.arn
  policy = data.aws_iam_policy_document.backups_sns_topic.json
}

resource "aws_backup_vault_notifications" "vault_notifications" {
  backup_vault_name   = aws_backup_vault.obi_vault.name
  sns_topic_arn       = aws_sns_topic.backups.arn
  backup_vault_events = ["BACKUP_JOB_STARTED", "RESTORE_JOB_COMPLETED"]
}
