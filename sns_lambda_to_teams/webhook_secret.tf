
#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "teams_webhook_url" {
  name                    = "${var.unique_name}_sns_to_teams_webhook_url"
  recovery_window_in_days = var.secret_recovery_window_in_days
}


