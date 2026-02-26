resource "aws_sns_topic" "topic" {
  name = "ses-emails-events"
}


data "aws_iam_policy_document" "allow_access_to_sns_topic" {
  policy_id = "aws_ses_events_sns_topic_policy"

  statement {
    actions = [
      "SNS:Publish",
    ]

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ses.amazonaws.com"]
    }

    resources = [
      aws_sns_topic.topic.arn,
    ]

    sid = "aws_ses_events_sns_topic_policy"
  }
}

resource "aws_sns_topic_policy" "allow_access_to_sns_topic" {
  arn    = aws_sns_topic.topic.arn
  policy = data.aws_iam_policy_document.allow_access_to_sns_topic.json
}
