#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "nexus_secrets" {
  name        = "nexus_secrets"
  description = "Nexus secret manager"
}
