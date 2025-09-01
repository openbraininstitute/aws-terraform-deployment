resource "aws_iam_policy" "secrets_access" {
  name        = "notebooks-service-secrets-access-policy"
  description = "Policy that gives access to the notebooks-service secrets"

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
}