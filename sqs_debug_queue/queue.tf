# Creates an SQS queue which listens to SNS and
# keeps messages for some time. This makes debugging
# much easier as it's not possible to see SNS events
# directly, while the AWS web UI allows you to inspect
# SQS events easily.

resource "aws_sqs_queue" "debug" {
  name                      = "${var.unique_short_name}-sns-debug"
  message_retention_seconds = var.message_retention_seconds
}

resource "aws_sqs_queue_policy" "debug_policy" {

  queue_url = aws_sqs_queue.debug.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect    = "Allow"
        Principal = "*"
        Action    = "SQS:SendMessage"
        Resource  = aws_sqs_queue.debug.arn
        Condition = {
          ArnEquals = {
            "aws:SourceArn" = var.sns_topic_arn
          }
        }
      }
    ]
  })
}

# Subscribe SQS queue to SNS topic
resource "aws_sns_topic_subscription" "debug_subscription" {
  topic_arn = var.sns_topic_arn
  protocol  = "sqs"
  endpoint  = aws_sqs_queue.debug.arn

  depends_on = [aws_sqs_queue_policy.debug_policy]
}
