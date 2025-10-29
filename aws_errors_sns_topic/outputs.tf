output "sns_topic_arn" {
  value       = aws_sns_topic.general_errors.arn
  description = "SNS topic ARN for AWS general errors notifications"
  sensitive   = false
}
