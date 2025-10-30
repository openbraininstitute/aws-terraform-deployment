resource "aws_sns_topic" "general_errors" {
  name = "general-error-events"
}

resource "aws_cloudwatch_event_rule" "ecs_task_state_changes" {
  name        = "aws-generic-error-event-rule"
  description = "Triggers on any event with eventType: ERROR"
  event_pattern = jsonencode({
    detail = {
      #lastStatus = ["RUNNING", "STOPPED"]
      "eventType" = ["WARN", "ERROR"]
    }
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state_changes.name
  target_id = "aws-generic-error-to-sns"
  arn       = aws_sns_topic.general_errors.arn
}

data "aws_iam_policy_document" "allow_eventbridge_sns_topic" {
  policy_id = "aws_generic_errors_sns_topic_policy"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.general_errors.arn,
    ]

    sid = "aws_generic_errors_sns_topic_policy"
  }
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn    = aws_sns_topic.general_errors.arn
  policy = data.aws_iam_policy_document.allow_eventbridge_sns_topic.json
}