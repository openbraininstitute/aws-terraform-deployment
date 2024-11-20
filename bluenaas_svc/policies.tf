resource "aws_iam_policy" "secrets_access" {
  name        = "bluenaas-service-secrets-access-policy"
  description = "Policy that gives access to the BlueNaaS service secrets"

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
          "${var.bluenaas_service_secrets_arn}"
        ]
      }
    ]
  })

  tags = {
    SBO_Billing = "bluenaas"
  }
}
