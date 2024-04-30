resource "aws_iam_policy" "dockerhub_access" {
  name        = "dockerhub-credentials-access-policy"
  description = "Policy that allows access to the dockerhub credentials"

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
        "${var.dockerhub_credentials_arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "common"
  }
}
