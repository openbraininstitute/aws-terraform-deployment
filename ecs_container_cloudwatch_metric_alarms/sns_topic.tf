resource "aws_sns_topic" "ecs_alerts" {
  name = "ecs-${var.short_name}-alerts"
}
