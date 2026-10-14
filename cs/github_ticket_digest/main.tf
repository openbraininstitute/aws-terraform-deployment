data "archive_file" "digest_archive" {
  type        = "zip"
  source_file = "${path.module}/src/github_ticket_digest.py"
  output_path = "${path.module}/src/github_ticket_digest.py.zip"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.unique_name}"
  retention_in_days = var.log_retention_in_days

  tags = merge({ Name = "${var.unique_name}-logs" }, var.tags)
}

resource "aws_lambda_function" "digest" {
  filename         = data.archive_file.digest_archive.output_path
  function_name    = var.unique_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "github_ticket_digest.handler"
  source_code_hash = data.archive_file.digest_archive.output_base64sha256
  runtime          = var.python_runtime
  timeout          = var.lambda_timeout_seconds

  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda_log_group.name
    log_format = "Text"
  }

  environment {
    variables = {
      GITHUB_TOKEN_SECRET_ID   = var.github_token_secret_arn
      GITHUB_TOKEN_SECRET_KEY  = var.github_token_secret_key
      TEAMS_WEBHOOK_SECRET_ID  = var.teams_webhook_secret_arn
      TEAMS_WEBHOOK_SECRET_KEY = var.teams_webhook_secret_key
      GITHUB_ORG               = var.github_org
      GITHUB_PROJECT_NUMBER    = tostring(var.project_number)
      GITHUB_LABELS            = join(",", var.labels)
      GITHUB_EXCLUDE_STATUSES  = join(",", var.exclude_statuses)
      STALE_DAYS               = tostring(var.stale_days)
      INCLUDE_PRS              = var.include_prs ? "true" : "false"
      MAX_ITEMS                = tostring(var.max_items)
    }
  }

  tags = merge({ Name = var.unique_name }, var.tags)

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}
