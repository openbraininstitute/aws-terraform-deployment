resource "aws_iam_policy" "full_secrets_access" {
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
          "${var.secrets_arn}",
          "${var.launch_system_capability_secrets_arn}"
        ]
      }
    ]
  }
  EOT
}

resource "aws_iam_policy" "launch_secrets_access" {
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
