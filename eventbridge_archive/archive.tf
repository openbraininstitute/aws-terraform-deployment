data "aws_cloudwatch_event_bus" "default" {
  name = "default"
}

resource "aws_cloudwatch_event_archive" "archive" {
  name             = var.eventbridge_archive_name
  description      = var.eventbridge_archive_description
  event_source_arn = data.aws_cloudwatch_event_bus.default.arn
  retention_days   = var.eventbridge_retention_days

  event_pattern = jsonencode({
    source = var.eventbridge_pattern_source
  })
}