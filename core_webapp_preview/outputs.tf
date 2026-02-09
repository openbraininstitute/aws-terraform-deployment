output "app_id" {
  value       = aws_amplify_app.this.id
  description = "Amplify app ID"
}

output "github_deploy_role_arn" {
  value       = aws_iam_role.github_deploy.arn
  description = "IAM role ARN for GitHub Actions to assume"
}
