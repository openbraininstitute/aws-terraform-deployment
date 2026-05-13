resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-${var.short_name}-alerts"
  tags = { SBO_Billing = var.sbo_billing_tag }
}
