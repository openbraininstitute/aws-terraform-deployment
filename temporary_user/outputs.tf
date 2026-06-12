output "aws_iam_user_access_key" {
  value     = aws_iam_access_key.temp_user_access_key.id
  sensitive = true
}

output "aws_iam_user_access_key_secret" {
  value     = aws_iam_access_key.temp_user_access_key.secret
  sensitive = true
}

output "temporary_user_arn" {
  value = aws_iam_user.temp_user.arn
}
