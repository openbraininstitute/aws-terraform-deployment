resource "aws_sns_topic" "rds_alerts" {
  name = "rds-${var.short_name}-alerts"
}
