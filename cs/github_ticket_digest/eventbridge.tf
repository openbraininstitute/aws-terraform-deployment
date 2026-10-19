# Weekly trigger implemented with EventBridge Scheduler (not an EventBridge
# rule) so the schedule can run in a named timezone and follow DST. The cron
# in var.schedule_expression is interpreted in var.schedule_timezone.

resource "aws_iam_role" "scheduler_role" {
  name = "${var.unique_name}-scheduler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "scheduler.amazonaws.com" }
    }]
  })

  tags = merge({ Name = "${var.unique_name}-scheduler-role" }, var.tags)
}

resource "aws_iam_policy" "scheduler_policy" {
  name = "${var.unique_name}-scheduler-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid    = "AllowInvokeDigestLambda"
      Effect = "Allow"
      Action = "lambda:InvokeFunction"
      Resource = [
        aws_lambda_function.digest.arn,
        "${aws_lambda_function.digest.arn}:*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "scheduler_policy_attach" {
  role       = aws_iam_role.scheduler_role.name
  policy_arn = aws_iam_policy.scheduler_policy.arn
}

resource "aws_scheduler_schedule" "weekly_schedule" {
  name        = "${var.unique_name}-schedule"
  description = "Weekly trigger for the stale GitHub ticket digest."

  flexible_time_window {
    mode = "OFF"
  }

  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_timezone

  target {
    arn      = aws_lambda_function.digest.arn
    role_arn = aws_iam_role.scheduler_role.arn
  }
}
