# IAM policy for SSO users to access SSM sessions
# This policy restricts users to only use their own SSM document

resource "aws_iam_policy" "ssm_user_access" {
  name        = "obi_SSMBastionUserAccess"
  description = "Allow SSO users to start SSM sessions using their own user mapping document"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowStartSessionOnInstances"
        Effect   = "Allow"
        Action   = "ssm:StartSession"
        Resource = "arn:aws:ec2:*:${data.aws_caller_identity.current.account_id}:instance/*"
      },
      {
        Sid    = "AllowStartSessionWithOwnDocument"
        Effect = "Allow"
        Action = "ssm:StartSession"
        Resource = [
          "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:document/SSM-UserMapping-*"
        ]
        Condition = {
          StringLike = {
            "aws:userid" = "*:$${ssm:resourceTag/AllowedEmail}"
          }
        }
      },
      {
        Sid      = "AllowTerminateOwnSessions"
        Effect   = "Allow"
        Action   = "ssm:TerminateSession"
        Resource = "arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:session/$${aws:username}-*"
      },
      {
        Sid    = "AllowDescribeInstances"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ssm:DescribeSessions",
          "ssm:GetConnectionStatus",
          "ssm:DescribeDocument",
          "ssm:GetDocument",
          "ssm:ListDocuments"
        ]
        Resource = "*"
      },
      {
        Sid    = "AllowKMSForSessionEncryption"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:GenerateDataKey"
        ]
        Resource = "*"
      }
    ]
  })
}

output "ssm_user_policy_arn" {
  description = "ARN of the IAM policy to attach to SSO permission sets"
  value       = aws_iam_policy.ssm_user_access.arn
}
