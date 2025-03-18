resource "aws_iam_policy" "sbo_core_webapp_secrets_access" {
  name        = "core-webapp-${var.key}-secrets-access-policy"
  description = "Policy that gives access to the core-webapp-${var.key} secrets"

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
        "${var.secrets_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "core_webapp"
  }
}
