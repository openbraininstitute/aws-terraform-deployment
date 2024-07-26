# Created in AWS secret manager
variable "nexus_secrets_arn" {
  type        = string
  description = "The ARN of the SBO nexus app secrets"
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "access_nexus_secrets" {
  name        = "nexus-secrets-access-policy"
  description = "Policy that gives access to the nexus secrets"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:${var.aws_region}:${var.aws_account_id}:secret:nexus*"
      ]
    }
  ]
}
EOF
}

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "dockerhub_credentials" {
  name                    = "nexus_dockerhub_credentials"
  description             = "The credentials of the NISE dockerhub account used to authenticate calls to dockerhub."
  recovery_window_in_days = var.secret_recovery_window_in_days
}

resource "aws_secretsmanager_secret_version" "example" {
  secret_id = aws_secretsmanager_secret.dockerhub_credentials.id
  secret_string = jsonencode({
    username = var.dockerhub_username,
    password = var.dockerhub_password
  })
}
