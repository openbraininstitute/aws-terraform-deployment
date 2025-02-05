# Output Access Key and Secret (Sensitive)
output "access_key_id" {
  value       = aws_iam_access_key.ses_user_key.id
  description = "Access Key ID for SES user"
}

output "secret_access_key" {
  value       = aws_iam_access_key.ses_user_key.secret
  description = "Secret Access Key for SES user"
  sensitive   = true # Prevents accidental exposure
}
