output "sns_topic_arn" {
  value       = aws_sns_topic.rds_alerts.arn
  description = "ARN of the SNS topic receiving RDS alerts"
}
