resource "aws_iam_policy" "secrets_access" {
  name        = "launch-service-secrets-access-policy"
  description = "Policy that gives access to the launch service secrets"

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
          "${var.secrets_arn}"
        ]
      }
    ]
  }
  EOT
}
