resource "aws_iam_policy" "secrets_access" {
  name        = "accounting-service-secrets-access-policy"
  description = "Policy that gives access to the accounting service secrets"

  policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ],
        "Resource": [
          "${var.accounting_service_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}

resource "aws_iam_policy" "writing_queues" {
  name        = "accounting-writing-queues"
  description = "Policy for writing to accounting queues"

  policy = jsonencode({
    Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
    Statement = [
      {
        Effect = "Allow"
        Action : [
          "sqs:GetQueueUrl",
          "sqs:SendMessage",
        ],
        "Resource" : [
          module.storage_event_queue_set.main_queue_arn,
          module.longrun_event_queue_set.main_queue_arn,
          module.oneshot_event_queue_set.main_queue_arn
        ]
      }
    ]
  })
}
