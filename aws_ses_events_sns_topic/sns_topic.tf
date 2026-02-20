resource "aws_sns_topic" "topic" {
  name = "ses-emails-events"
}

resource "aws_cloudwatch_event_rule" "event_rule" {
  name        = "aws-generic-error-event-rule"
  description = "Triggers on any event with eventType: ERROR"
  event_pattern = jsonencode({
    "source" : ["aws.ses"],
    "detail-type" : [
      "Email Bounced",
      "Email Clicked",
      "Email Complaint Received",
      "Email Delivered",
      "Email Delivery Delayed",
      "Email Opened",
      "Email Rejected",
      "Email Rendering Failed",
      "Email Sent",
      "Email Subscribed"
    ]
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = "aws-ses-events-to-sns"
  arn       = aws_sns_topic.topic.arn
}

data "aws_iam_policy_document" "allow_eventbridge_sns_topic" {
  policy_id = "aws_ses_events_sns_topic_policy"

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
      aws_sns_topic.topic.arn,
    ]

    sid = "aws_ses_events_sns_topic_policy"
  }
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.allow_eventbridge_sns_topic.json
}
