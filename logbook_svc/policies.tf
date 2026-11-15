# Derived secret (Secrets Manager): the server takes one DATABASE_URL,
# and ECS injects secrets whole, so the URL with the password inside is
# built here from the RDS endpoint and DB_PASS of the common secret.
# The password is already in the Terraform state through the RDS
# resource, as for every database of this repository.
#
# sslmode=require: TLS on every connection (rds.force_ssl=1 refuses
# plain text). The certificate is not verified (libpq meaning of
# "require"); verify-full needs the RDS CA bundle in the image.
resource "aws_secretsmanager_secret" "logbook_runtime" {
  name_prefix             = "logbook-runtime-"
  description             = "Logbook server: DATABASE_URL, built by Terraform"
  recovery_window_in_days = 7 # rebuilt by the next apply; no need for the 30-day default
}

resource "aws_secretsmanager_secret_version" "logbook_runtime" {
  secret_id = aws_secretsmanager_secret.logbook_runtime.id
  secret_string = jsonencode({
    DATABASE_URL = format(
      "postgres://%s:%s@%s:%d/%s?sslmode=require",
      var.db_username,
      # urlencode writes a space as "+", which a URL password reads as a plus sign
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
