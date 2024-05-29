# Created in AWS secret manager
variable "sbo_core_webapp_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:sbo_core_webapp-bwv3ZT"
  type        = string
  description = "The ARN of the SBO core webapp secrets"
  sensitive   = true
}

resource "aws_iam_policy" "sbo_core_webapp_secrets_access" {
  name        = "sbo-core-webapp-secrets-access-policy"
  description = "Policy that gives access to the SBO core webapp secrets"

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
        "${var.sbo_core_webapp_secrets_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "core_webapp"
  }
}
