data "archive_file" "doi_redirect" {
  type        = "zip"
  source_file = "${path.module}/src/redirect.py"
  output_path = "${path.module}/src/redirect_payload.zip"
}

resource "aws_lambda_function" "doi_redirect" {
  filename         = data.archive_file.doi_redirect.output_path
  function_name    = "lambda_redirect"
  role             = aws_iam_role.lambda_role.arn
  handler          = "redirect.lambda_redirect"
  source_code_hash = data.archive_file.doi_redirect.output_base64sha256
  runtime          = "python3.11"
}



resource "aws_iam_role" "lambda_role" {
  name = "doi_redirect_lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_policy_attachment" "lambda_execution_attach" {
  name       = "lambda_execution_attach"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lb_target_group" "lambda_target_group" {
  name        = "doi-redirect-lambda"
  target_type = "lambda"
}

resource "aws_lb_target_group_attachment" "lambda_attachment" {
  target_group_arn = aws_lb_target_group.lambda_target_group.arn
  target_id        = aws_lambda_function.doi_redirect.arn
}

resource "aws_lambda_permission" "alb_invocation" {
  statement_id  = "AllowALBInvokeDoiRedirect"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doi_redirect.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.lambda_target_group.arn
}

resource "aws_lb_listener_rule" "lambda_rule" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 5

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/doi/*"]
    }
  }
}
