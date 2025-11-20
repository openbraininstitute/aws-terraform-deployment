resource "aws_iam_policy" "secrets_access" {
  name        = "launch_system_secrets_access_policy"
  description = "Policy that gives access to the launch system secrets"

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
