

resource "aws_sqs_queue" "errors_debug" {
  count = var.include_sqs_debug_queue ? 1 : 0

  name                      = "${var.unique_short_name}-errors-in-logs-debug"
  message_retention_seconds = 3600 # 1 hour
}

resource "aws_sqs_queue_policy" "errors_debug_policy" {
  count = var.include_sqs_debug_queue ? 1 : 0

  queue_url = aws_sqs_queue.errors_debug[0].id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.errors_debug[0].arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = aws_sns_topic.errors.arn
          }
        }
      }
    ]
  })
}

# Subscribe SQS queue to SNS topic
resource "aws_sns_topic_subscription" "example" {
  count = var.include_sqs_debug_queue ? 1 : 0

  topic_arn = aws_sns_topic.errors.arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.errors_debug[0].arn

  depends_on = [aws_sqs_queue_policy.errors_debug_policy[0]]
}
