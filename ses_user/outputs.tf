# Output Access Key and Secret (Sensitive)
output "access_key_id" {
  value       = aws_iam_access_key.ses_user_key.id
  description = "Access Key ID for SES user"
}

output "ses_smtp_password_v4" {
  value       = aws_iam_access_key.ses_user_key.ses_smtp_password_v4
  description = "Password for SMTP for SES user"
  sensitive   = true # Prevents accidental exposure
}
