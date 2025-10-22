# Log group we'll take the messages from
data "aws_cloudwatch_log_group" "input" {
  name = var.log_group_name
}


# Note: no rolfe for the subscription filter, as there's an aws_lambda_permission block
# which allows aws logs to invoke the lambda.
resource "aws_cloudwatch_log_subscription_filter" "errors" {
  name            = "${var.unique_short_name}-filter-errors-in-logs"
  log_group_name  = var.log_group_name
  destination_arn = aws_lambda_function.cwlogs_to_sns.arn
  filter_pattern  = var.filter_pattern

  depends_on = [aws_lambda_permission.allow_logs]
}

resource "aws_sns_topic" "errors" {
  name = "${var.unique_short_name}-errors-in-logs"
}


# Role for the lambda itself
resource "aws_iam_role" "lambda_role" {
  name = "${var.unique_short_name}-filter-errors-in-logs-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "lambda.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_can_make_logs_itself_and_publish_to_sns" {
  name_prefix = "${var.unique_short_name}-filter-errors-in-logs-lambda-extras-policy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = ["*"],
      },
      {
        Effect   = "Allow",
        Action   = ["sns:Publish"],
        Resource = [aws_sns_topic.errors.arn],
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_extra_policies" {
  role       = aws_iam_role.lambda_role.id
  policy_arn = aws_iam_policy.lambda_can_make_logs_itself_and_publish_to_sns.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${var.unique_short_name}-filter-errors-in-logs"
  retention_in_days = 5
  log_group_class   = "INFREQUENT_ACCESS"
}

data "archive_file" "sns_to_teams_archive" {
  type        = "zip"
  source_file = "${path.module}/src/${var.python_script_name}"
  output_path = "${path.module}/src/${var.python_script_name}.zip"
}

resource "aws_lambda_function" "cwlogs_to_sns" {
  function_name    = "${var.unique_short_name}-filter-errors-in-logs"
  role             = aws_iam_role.lambda_role.arn
  runtime          = var.python_runtime
  handler          = var.handler
  filename         = data.archive_file.sns_to_teams_archive.output_path
  source_code_hash = data.archive_file.sns_to_teams_archive.output_base64sha256

  environment {
    variables = {
      TOPIC_ARN = aws_sns_topic.errors.arn
    }
  }
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
    log_group             = aws_cloudwatch_log_group.lambda_log_group.name
  }
  architectures = ["arm64"] # should be cheaper

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

resource "aws_lambda_permission" "allow_logs" {
  statement_id  = "AllowCWLogsInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cwlogs_to_sns.function_name
  principal     = "logs.${var.region}.amazonaws.com"
  source_arn    = "${data.aws_cloudwatch_log_group.input.arn}:*"
}