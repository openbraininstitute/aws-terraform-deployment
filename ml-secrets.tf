# Created in AWS secret manager
variable "ml_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:ml_secrets-uEWnHv"
  type        = string
  description = "The ARN of the ML secrets"
  sensitive   = true
}

resource "aws_iam_policy" "ml_secrets_access" {
  name        = "ml-secrets-access-policy"
  description = "Policy that gives access to the ML secrets"

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
        "${var.ml_secrets_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "machinelearning"
  }
}

