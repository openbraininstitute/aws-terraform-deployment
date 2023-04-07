# Created in AWS secret manager
variable "dockerhub_credentials_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:dockerhub-bbpbuildbot-EhUqqE"
  type        = string
  description = "The ARN of the secret containing the credentials for dockerhub to fetch images from private dockerhub repos"
  sensitive   = true
}

resource "aws_iam_policy" "dockerhub_access" {
  name        = "dockerhub-credentiasl-access-policy"
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
}
