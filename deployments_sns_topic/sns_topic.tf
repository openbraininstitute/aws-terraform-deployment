resource "aws_sns_topic" "deployments" {
  name = "deployment-events"
}

resource "aws_cloudwatch_event_rule" "ecs_task_state_changes" {
  name        = "ecs-task-state-change-rule"
  description = "Triggers on ECS task RUNNING and STOPPED states"
  event_pattern = jsonencode({
    source = ["aws.ecs"]
    # source        = ["aws.ecs"],
    # "detail-type" = ["ECS Task State Change"],
    # detail = {
    #   lastStatus = ["RUNNING", "STOPPED"]
    # }
  })
}

resource "aws_cloudwatch_event_target" "send_to_sns" {
  rule      = aws_cloudwatch_event_rule.ecs_task_state_changes.name
  target_id = "ecs-task-to-sns"
  arn       = aws_sns_topic.deployments.arn
}

data "aws_iam_policy_document" "allow_eventbridge_sns_topic" {
  policy_id = "deployments_sns_topic_policy"

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
      aws_sns_topic.deployments.arn,
    ]

    sid = "deployments_sns_topic_policy"
  }
}

resource "aws_sns_topic_policy" "allow_eventbridge" {
  arn    = aws_sns_topic.deployments.arn
  policy = data.aws_iam_policy_document.allow_eventbridge_sns_topic.json
}