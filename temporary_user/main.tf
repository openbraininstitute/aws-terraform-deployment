resource "aws_iam_user" "temp_user" {
  name = var.user_name
}

resource "aws_iam_user_policy" "temp_user_policy" {
  name = "PolicyFor${var.user_name}"
  user = aws_iam_user.temp_user.name

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [for action in var.allow_resource_actions : { Effect = "Allow", Action = action["allow_actions"], Resource = action["resources"] }]
  })
}

resource "aws_iam_policy_attachment" "extra_policy" {
  for_each   = toset(var.extra_policies)
  name       = "extra policy${sha256(each.key)}"
  policy_arn = each.key
  users      = [aws_iam_user.temp_user.id]
}

resource "aws_iam_access_key" "temp_user_access_key" {
  user = aws_iam_user.temp_user.name
}
