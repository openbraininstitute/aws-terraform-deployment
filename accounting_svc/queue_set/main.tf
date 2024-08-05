#tfsec:ignore:aws-sqs-enable-queue-encryption
resource "aws_sqs_queue" "main_queue" {
  name                        = var.main_queue_name
  fifo_queue                  = true
  content_based_deduplication = true
  max_message_size            = 262144
  message_retention_seconds   = 1209600
  receive_wait_time_seconds   = 20
  visibility_timeout_seconds  = 60

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = 5
  })

  tags = {
    Name        = var.main_queue_name
    SBO_Billing = "accounting"
  }
}

#tfsec:ignore:aws-sqs-enable-queue-encryption
resource "aws_sqs_queue" "dlq" {
  name                        = var.dlq_name
  fifo_queue                  = true
  content_based_deduplication = true
  message_retention_seconds   = 1209600

  tags = {
    Name        = var.dlq_name
    SBO_Billing = "accounting"
  }
}

resource "aws_sqs_queue_redrive_allow_policy" "redrive_allow_policy" {
  queue_url = aws_sqs_queue.dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue",
    sourceQueueArns   = [aws_sqs_queue.main_queue.arn]
  })
}

data "aws_iam_policy_document" "queue_policy" {
  version = "2012-10-17"
  statement {
    sid    = "ReceiveMessage"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:GetQueueUrl",
      "sqs:GetQueueAttributes",
      "sqs:ReceiveMessage",
    ]
    resources = [aws_sqs_queue.main_queue.arn]

    principals {
      type        = "AWS"
      identifiers = [var.read_arn]
    }
  }

  statement {
    sid    = "SendMessage"
    effect = "Allow"
    actions = [
      "sqs:SendMessage"
    ]
    resources = [aws_sqs_queue.main_queue.arn]

    principals {
      type        = "AWS"
      identifiers = [var.read_arn]
    }
  }
}

resource "aws_sqs_queue_policy" "main_queue_policy" {
  queue_url = aws_sqs_queue.main_queue.url
  policy    = data.aws_iam_policy_document.queue_policy.json
}
