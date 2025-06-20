resource "aws_iam_policy" "secrets_access" {
  name        = "small-scale-simulator-service-secrets-access-policy"
  description = "Policy that gives access to the Small Scale Simulator service secrets"

  policy = jsonencode({
    Version : "2012-10-17",
    Statement : [
      {
        Effect : "Allow",
        Action : [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue"
        ],
        Resource : [
          var.secrets_arn
        ]
      }
    ]
  })
}
