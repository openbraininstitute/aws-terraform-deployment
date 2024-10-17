#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "ml_secrets_manager" {
  name        = "ml_secrets_manager"
  description = "ML Secrets Manager"
}
