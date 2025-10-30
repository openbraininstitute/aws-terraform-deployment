resource "aws_iam_policy" "auth_manager_secrets_access" {
  name        = "auth_manager-secrets-access-policy"
  description = "Policy that gives access to the auth_manager service secrets"

  policy = <<-EOT
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
          "${var.auth_manager_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}


