locals {
  python_version = "python3.11"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "handler_default" {
  name              = "/aws/lambda/${local.cluster_name}_handler_default"
  retention_in_days = 3
  tags              = var.tags
}

data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/src/handler.py"
  output_path = "${path.module}/src/handler_payload.zip"
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "handler_cors" {
  name              = "/aws/lambda/${local.cluster_name}_handler_cors"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "handler_cors" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-handler-cors"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.handler_cors.arn}:*"
      }]
    })
  }
  tags = var.tags
}

resource "aws_lambda_function" "handler_cors" {
  filename         = data.archive_file.handler.output_path
  function_name    = "${local.cluster_name}_handler_cors"
  role             = aws_iam_role.handler_cors.arn
  handler          = "handler.cors"
  timeout          = 30
  source_code_hash = data.archive_file.handler.output_base64sha256
  runtime          = local.python_version
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  tags = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "handler_session" {
  name              = "/aws/lambda/${local.cluster_name}_handler_session"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "handler_session" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-handler-session-logs"
    policy = jsonencode({
      Version = "2012-10-17" #tfsec:ignore:aws-iam-no-policy-wildcards
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.handler_session.arn}:*"
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-session-ecs-tasks"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["ecs:RunTask"]
        Effect   = "Allow"
        Resource = aws_ecs_task_definition.this.arn
        }, {
        Action   = ["ecs:TagResource", "ecs:DescribeTasks"]
        Effect   = "Allow"
        Resource = "arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_task_definition.this.family}/*"
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-session-ddb"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.this.arn
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-session-pass-roles"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["iam:PassRole"]
        Effect   = "Allow"
        Resource = [aws_iam_role.task.arn, aws_iam_role.task_exec.arn]
      }]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
  tags = var.tags
}

resource "aws_lambda_function" "handler_session" {
  filename         = data.archive_file.handler.output_path
  function_name    = "${local.cluster_name}_handler_session"
  role             = aws_iam_role.handler_session.arn
  handler          = "handler.session"
  timeout          = 30
  source_code_hash = data.archive_file.handler.output_base64sha256
  runtime          = local.python_version
  environment {
    variables = {
      "APIGW_REGION"     = var.aws_region
      "DDB_ID_TASK"      = aws_dynamodb_table.this.name
      "ECS_CLUSTER"      = aws_ecs_cluster.this.name
      "ECS_TASK_DEF"     = aws_ecs_task_definition.this.arn
      "SVC_SUBNET"       = var.ecs_subnet_id
      "SVC_SECURITY_GRP" = var.ecs_secgrp_id
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  vpc_config {
    security_group_ids = [var.ecs_secgrp_id]
    subnet_ids         = [var.ecs_subnet_id]
  }
  depends_on = [aws_cloudwatch_log_group.handler_default]
  tags       = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "handler_auth" {
  name              = "/aws/lambda/${local.cluster_name}_handler_auth"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "handler_auth" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-handler-auth-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.handler_auth.arn}:*"
      }]
    })
  }
  inline_policy { # needs to wait for task becoming healthy
    name = "${var.svc_name}-handler-session-ecs-tasks"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["ecs:DescribeTasks"]
        Effect   = "Allow"
        Resource = "arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_task_definition.this.family}/*"
      }]
    })
  }
  inline_policy { # update healthy task ip
    name = "${var.svc_name}-handler-auth-ddb-get-item"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:GetItem", "dynamodb:UpdateItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.this.arn
      }]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
  tags = var.tags
}

resource "aws_lambda_function" "handler_auth" {
  filename         = data.archive_file.handler.output_path
  function_name    = "${local.cluster_name}_handler_auth"
  role             = aws_iam_role.handler_auth.arn
  handler          = "handler.auth"
  timeout          = 30
  source_code_hash = data.archive_file.handler.output_base64sha256
  runtime          = local.python_version
  environment {
    variables = {
      "DDB_ID_TASK" = aws_dynamodb_table.this.name
      "ECS_CLUSTER" = aws_ecs_cluster.this.name
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  vpc_config {
    security_group_ids = [var.ecs_secgrp_id]
    subnet_ids         = [var.ecs_subnet_id]
  }
  tags = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "handler_launch" {
  name              = "/aws/lambda/${local.cluster_name}_handler_launch"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "handler_launch" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-handler-launch-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.handler_launch.arn}:*"
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-launch-key-access"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["secretsmanager:GetSecretValue"]
        Effect   = "Allow"
        Resource = var.id_rsa_scr
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-launch-ddb-get-item"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.this.arn
      }]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
  tags = var.tags
}

resource "aws_lambda_function" "handler_launch" {
  filename         = data.archive_file.handler.output_path
  function_name    = "${local.cluster_name}_handler_launch"
  role             = aws_iam_role.handler_launch.arn
  handler          = "handler.launch"
  timeout          = 30
  source_code_hash = data.archive_file.handler.output_base64sha256
  runtime          = local.python_version
  environment {
    variables = {
      "DDB_ID_TASK" = aws_dynamodb_table.this.name
      "KEY_ARN"     = var.id_rsa_scr
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  vpc_config {
    security_group_ids = [var.ecs_secgrp_id]
    subnet_ids         = [var.ecs_subnet_id]
  }
  tags = var.tags
}

resource "aws_iam_role" "handler_default" {
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-handler-default-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.handler_default.arn}:*"
      }]
    })
  }
  inline_policy {
    name = "${var.svc_name}-handler-default-ddb-get-item"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["dynamodb:GetItem"]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.this.arn
      }]
    })
  }
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
  ]
  tags = var.tags
}

resource "aws_lambda_function" "handler_default" {
  filename         = data.archive_file.handler.output_path
  function_name    = "${local.cluster_name}_handler_default"
  role             = aws_iam_role.handler_default.arn
  handler          = "handler.default"
  timeout          = 30
  source_code_hash = data.archive_file.handler.output_base64sha256
  runtime          = local.python_version
  environment {
    variables = {
      "APIGW_REGION"     = var.aws_region
      "DDB_ID_TASK"      = aws_dynamodb_table.this.name
      "ECS_CLUSTER"      = aws_ecs_cluster.this.name
      "ECS_TASK_DEF"     = aws_ecs_task_definition.this.arn
      "SVC_SUBNET"       = var.ecs_subnet_id
      "SVC_SECURITY_GRP" = var.ecs_secgrp_id
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  vpc_config {
    security_group_ids = [var.ecs_secgrp_id]
    subnet_ids         = [var.ecs_subnet_id]
  }
  depends_on = [aws_cloudwatch_log_group.handler_default]
  tags       = var.tags
}

# AUTHZ
data "archive_file" "authz" {
  type        = "zip"
  source_file = "${path.module}/src/authz.py"
  output_path = "${path.module}/src/authz_payload.zip"
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "authz_token" {
  name              = "/aws/lambda/${local.cluster_name}_authz_token"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "authz_token_logs" {
  name               = "${var.svc_name}-authz-token-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-authz-token-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.authz_token.arn}:*"
      }]
    })
  }
  tags = var.tags
}

resource "aws_lambda_function" "authz_token" {
  filename         = data.archive_file.authz.output_path
  function_name    = "${local.cluster_name}_authz_token"
  role             = aws_iam_role.authz_token_logs.arn
  handler          = "authz.token"
  source_code_hash = data.archive_file.authz.output_base64sha256
  runtime          = local.python_version
  environment {
    variables = {
      "USER_INFO" = "https://openbluebrain.com/auth/realms/SBO/protocol/openid-connect/userinfo"
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  depends_on = [aws_cloudwatch_log_group.authz_token]
  tags       = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "authz_cookie" {
  name              = "/aws/lambda/${local.cluster_name}_authz_cookie"
  retention_in_days = 3
  tags              = var.tags
}

resource "aws_iam_role" "authz_cookie_logs" {
  name               = "${var.svc_name}-authz-cookie-logs"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  inline_policy {
    name = "${var.svc_name}-authz-cookie-logs"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["logs:CreateLogStream", "logs:PutLogEvents"]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.authz_cookie.arn}:*"
      }]
    })
  }
  tags = var.tags
}

resource "aws_lambda_function" "authz_cookie" {
  filename         = data.archive_file.authz.output_path
  function_name    = "${local.cluster_name}_authz_cookie"
  role             = aws_iam_role.authz_cookie_logs.arn
  handler          = "authz.cookie"
  source_code_hash = data.archive_file.authz.output_base64sha256
  runtime          = local.python_version
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  depends_on = [aws_cloudwatch_log_group.authz_cookie]
  tags       = var.tags
}
