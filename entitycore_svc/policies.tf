resource "aws_iam_policy" "secrets_access" {
  name        = "entitycore-service-secrets-access-policy"
  description = "Policy that gives access to the entitycore service secrets"

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
          "${var.entitycore_service_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}

resource "aws_iam_policy" "s3_access" {
  name        = "entitycore-service-s3-access-policy"
  description = "Policy that gives access to the entitycore service S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

# Attach the policy to the task role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.ecs_entitycore_task_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}
