# ECS injects whole secrets and the server wants one DATABASE_URL, so Terraform builds it here.
# Limit: sslmode=require does not check the server certificate. Upgrade: verify-full with the RDS CA bundle.
resource "aws_secretsmanager_secret" "logbook_runtime" {
  name_prefix             = "logbook-runtime-"
  description             = "Logbook server: DATABASE_URL, built by Terraform"
  recovery_window_in_days = 7 # the next apply rebuilds it, so no need for the 30-day default
}

resource "aws_secretsmanager_secret_version" "logbook_runtime" {
  secret_id = aws_secretsmanager_secret.logbook_runtime.id
  secret_string = jsonencode({
    DATABASE_URL = format(
      "postgres://%s:%s@%s:%d/%s?sslmode=require",
      var.db_username,
      # urlencode turns a space into "+", which a URL password reads as a real plus
      replace(urlencode(jsondecode(data.aws_secretsmanager_secret_version.logbook.secret_string)["DB_PASS"]), "+", "%20"),
      aws_db_instance.logbook.address,
      aws_db_instance.logbook.port,
      var.db_name,
    )
  })
}

resource "aws_iam_policy" "secrets_access" {
  name        = "logbook-service-secrets-access-policy"
  description = "Policy that gives access to the logbook service secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
        Resource = [aws_secretsmanager_secret.logbook_runtime.arn]
      }
    ]
  })
}
