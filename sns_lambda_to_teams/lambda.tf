data "archive_file" "sns_to_teams_archive" {
  type        = "zip"
  source_file = "${path.module}/src/${var.python_script_name}"
  output_path = "${path.module}/src/${var.python_script_name}.zip"
}

resource "aws_lambda_function" "function" {
  filename         = data.archive_file.sns_to_teams_archive.output_path
  function_name    = var.python_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.handler
  source_code_hash = data.archive_file.sns_to_teams_archive.output_base64sha256
  runtime          = var.python_runtime

  logging_config {
    log_group  = aws_cloudwatch_log_group.lambda_log_group.name
    log_format = "Text"
  }

  environment {
    variables = {
      TEAMS_WEBHOOK_SECRET_NAME = aws_secretsmanager_secret.teams_webhook_url.name
    }
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

resource "aws_iam_role" "lambda_role" {
  name = "${var.unique_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}


resource "aws_sns_topic_subscription" "lambda_sub" {
  topic_arn = var.sns_topic_arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.function.arn
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = var.sns_topic_arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.unique_name}-sns-to-teams"
  retention_in_days = 14
}

resource "aws_iam_policy" "lambda_policy" {
  name = "${var.unique_name}-lambda-sns-to-teams-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowSecretRead"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.teams_webhook_url.arn
      },
      {
        Sid    = "AllowLogging"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attach" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}