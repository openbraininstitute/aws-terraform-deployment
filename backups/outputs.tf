output "sns_topic_arn" {
  value       = aws_sns_topic.backups.arn
  description = "SNS topic ARN for AWS Backup Vault notifications"
  sensitive   = false
}
