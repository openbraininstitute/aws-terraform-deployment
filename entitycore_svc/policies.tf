resource "aws_iam_policy" "secrets_access" {
  name        = "entitycore-service-secrets-access-policy"
  description = "Policy that gives access to the entitycore service secrets"

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
          "${var.entitycore_service_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}
