# IAM User for SES
resource "aws_iam_user" "ses_user" {
  name = var.user_name
}

# IAM Inline Policy Attached to User
resource "aws_iam_user_policy" "ses_inline_policy" {
  name = "AmazonSesSendingAccess"
  user = aws_iam_user.ses_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["ses:SendEmail", "ses:SendRawEmail"]
        Resource = "*"
      }
    ]
  })
}

# Generate Access Key for the IAM User
resource "aws_iam_access_key" "ses_user_key" {
  user = aws_iam_user.ses_user.name
}
