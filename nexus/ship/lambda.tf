data "archive_file" "python_lambda_package" {
  type        = "zip"
  source_file = "${path.module}/lambda_trigger_ecs.py"
  output_path = "ship_lambda.zip"
}

resource "aws_lambda_function" "launch_ship" {
  function_name    = "nexus_launch_ship_task"
  filename         = "ship_lambda.zip"
  source_code_hash = data.archive_file.python_lambda_package.output_base64sha256
  role             = aws_iam_role.nexus_ship_lambda.arn
  runtime          = "python3.12"
  architectures    = ["arm64"]
  handler          = "lambda_function.lambda_handler"
  timeout          = 10

  tracing_config {
    mode = "Active"
  }
}