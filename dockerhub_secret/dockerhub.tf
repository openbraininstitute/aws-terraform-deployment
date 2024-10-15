#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "dockerhub_bbpbuildbot_password" {
  name        = "dockerhub_bbpbuildbot_password"
  description = "dockerhub bbpbuildbot user password"
}

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
        "${aws_secretsmanager_secret.dockerhub_bbpbuildbot_password.arn}"
      ]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "common"
  }
}
