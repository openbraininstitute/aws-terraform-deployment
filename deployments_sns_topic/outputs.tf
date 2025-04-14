output "sns_topic_arn" {
  value       = aws_sns_topic.deployments.arn
  description = "SNS topic ARN for AWS deployment notifications"
  sensitive   = false
}
