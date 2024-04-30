output "dockerhub_credentials_arn" {
  description = "ARN of the secret containing the dockerhub credentials"
  value       = var.dockerhub_credentials_arn
  sensitive   = false
}

output "dockerhub_access_iam_policy_arn" {
  description = "ARN of the IAM policy that gives access to the dockerhub credential"
  value       = aws_iam_policy.dockerhub_access.arn
  sensitive   = false
}
