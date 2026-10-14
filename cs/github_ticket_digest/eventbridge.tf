resource "aws_cloudwatch_event_rule" "weekly_schedule" {
  name                = "${var.unique_name}-schedule"
  description         = "Weekly trigger for the stale GitHub ticket digest."
  schedule_expression = var.schedule_expression

  tags = merge({ Name = "${var.unique_name}-schedule" }, var.tags)
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.weekly_schedule.name
  target_id = "TriggerGithubTicketDigest"
  arn       = aws_lambda_function.digest.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.digest.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.weekly_schedule.arn
}
