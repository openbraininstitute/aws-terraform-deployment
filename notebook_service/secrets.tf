resource "aws_secretsmanager_secret" "secrets" {
  name                    = "notebook_service_secrets"
  recovery_window_in_days = var.secret_recovery_window_in_days
}

resource "aws_iam_policy" "secrets_access" {
  name        = "notebook_service_secrets_access_policy"
  description = "Policy that gives access to the notebook-service secrets"

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
        "${aws_secretsmanager_secret.secrets.arn}"
      ]
    }
  ]
}
EOF
}
