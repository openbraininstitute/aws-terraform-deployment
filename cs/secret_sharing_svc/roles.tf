resource "aws_iam_policy" "ecsTaskLogs" {
  name        = "secret-sharing-svc-ecsTaskLogs"
  description = "Allows ECS tasks to call AWS services on your behalf"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams",
          "logs:PutLogEvents",
        ]
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${aws_cloudwatch_log_group.secret_sharing_svc.name}*"
      }
    ]
  })

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}

### IAM roles and policies needed for keyloak-task logging
resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "secret-sharing-svc-ecs-task-execution-role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment_logs" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = aws_iam_policy.ecsTaskLogs.arn
}
