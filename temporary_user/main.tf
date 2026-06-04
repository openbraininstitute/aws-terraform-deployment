resource "aws_iam_user" "temp_user" {
  name = var.user_name
}

resource "aws_iam_user_policy" "temp_user_policy" {
  name = "PolicyFor${var.user_name}"
  user = aws_iam_user.temp_user.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = var.allow_actions
        Resource = var.allow_resources
      }
    ]
  })
}

resource "aws_iam_access_key" "temp_user_access_key" {
  user = aws_iam_user.temp_user.name
}
