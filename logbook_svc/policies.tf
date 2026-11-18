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
      replace(urlencode(local.common_secret["DB_PASS"]), "+", "%20"),
      aws_db_instance.logbook.address,
      aws_db_instance.logbook.port,
      var.db_name,
    )
    # The EntityCore sync signs in as the Keycloak client logbook-server with this.
    KEYCLOAK_SERVICE_CLIENT_SECRET = lookup(local.common_secret, "KEYCLOAK_SERVICE_CLIENT_SECRET", "")
  })

  lifecycle {
    precondition {
      condition     = contains(keys(local.common_secret), "KEYCLOAK_SERVICE_CLIENT_SECRET")
      error_message = "Add the key KEYCLOAK_SERVICE_CLIENT_SECRET (the secret of the Keycloak client logbook-server) to logbook_service_secrets_arn."
    }
  }
}

locals {
  common_secret = jsondecode(data.aws_secretsmanager_secret_version.logbook.secret_string)
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
