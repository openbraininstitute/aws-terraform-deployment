variable "actions" {
  type    = set(string)
  default = ["connect", "default", "disconnect"]
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

data "aws_iam_policy_document" "ws_handler_connect" {
  statement {
    actions   = ["ecs:RunTask"]
    resources = [aws_ecs_task_definition.this.arn]
    effect    = "Allow"
  }
  statement {
    actions   = ["ecs:TagResource"]
    resources = ["arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_task_definition.this.family}/*"]
    effect    = "Allow"
  }
  statement {
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.task_exec.arn]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ws_handler_connect" {
  name   = "${var.svc_name}-ws-handler-connect"
  policy = data.aws_iam_policy_document.ws_handler_connect.json
  tags   = var.tags
}

data "aws_iam_policy_document" "ws_handler_default" {
  statement {
    actions   = ["ecs:DescribeTasks"]
    resources = ["arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_task_definition.this.family}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ws_handler_default" {
  name   = "${var.svc_name}-ws-handler-default"
  policy = data.aws_iam_policy_document.ws_handler_default.json
  tags   = var.tags
}

data "aws_iam_policy_document" "ws_handler_disconnect" {
  statement {
    actions   = ["ecs:StopTask"]
    resources = ["arn:aws:ecs:${var.aws_region}:${var.account_id}:task/${aws_ecs_task_definition.this.family}/*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ws_handler_disconnect" {
  name   = "${var.svc_name}-ws-handler-disconnect"
  policy = data.aws_iam_policy_document.ws_handler_disconnect.json
  tags   = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ws_handler" {
  for_each          = var.actions
  name              = "/aws/lambda/${local.cluster_name}_ws_handler_${each.value}"
  retention_in_days = 3
  tags              = var.tags
}

data "aws_iam_policy_document" "ws_handler_logs" {
  for_each = var.actions
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.ws_handler[each.key].arn}:*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ws_handler_logs" {
  for_each = var.actions
  policy   = data.aws_iam_policy_document.ws_handler_logs[each.key].json
  tags     = var.tags
}

resource "aws_iam_role" "ws_handler" {
  for_each           = var.actions
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = concat(
    [aws_iam_policy.ws_handler_logs[each.key].arn, aws_iam_policy.ddb_ws_conn_task[each.key].arn],
    "connect" == each.key ? [aws_iam_policy.ws_handler_connect.arn] : [],
    "default" == each.key ? [aws_iam_policy.ws_handler_default.arn] : [],
    "disconnect" == each.key ? [
      aws_iam_policy.ws_handler_disconnect.arn,
      aws_iam_policy.ddb_ecs_task_acc.arn,
    ] : [],
    # default/disconnect lambda should run in vpc to access ECS task endpoint
  contains(["default", "disconnect"], each.key) ? ["arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"] : [])
  tags = var.tags
}

data "archive_file" "ws_handler" {
  type        = "zip"
  source_file = "${path.module}/src/ws_handler.py"
  output_path = "${path.module}/src/ws_handler_payload.zip"
}

resource "aws_lambda_function" "ws_handler" {
  for_each         = var.actions
  filename         = data.archive_file.ws_handler.output_path
  function_name    = "${local.cluster_name}_ws_handler_${each.value}"
  role             = aws_iam_role.ws_handler[each.key].arn
  handler          = "ws_handler.${each.value}"
  source_code_hash = data.archive_file.ws_handler.output_base64sha256
  runtime          = "python3.10"
  timeout          = each.value == "default" ? 29 : 10 # defalut route should wait for svc <29s(apigw ws timeout)
  environment {
    variables = {
      "DDB_WS_CONN_TASK"          = aws_dynamodb_table.ws_conn_task.name
      "DDB_ECS_TASK_ACC"          = aws_dynamodb_table.ecs_task_acc.name
      "APIGW_ENDPOINT"            = "https://${aws_apigatewayv2_api.this.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_apigatewayv2_stage.prod.name}"
      "APIGW_REGION"              = var.aws_region
      "ECS_CLUSTER"               = aws_ecs_cluster.this.name
      "ECS_TASK_DEF"              = aws_ecs_task_definition.this.arn
      "ECS_TASK_NAME"             = aws_ecs_task_definition.this.family
      "ECS_STOP_ON_WS_DISCONNECT" = var.ecs_stop_on_ws_disconnect ? "True" : ""
      "SVC_SUBNET"                = var.ecs_subnet_id
      "SVC_SECURITY_GRP"          = aws_security_group.ecs.id
      "SVC_BUCKET"                = var.svc_bucket
    }
  }
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  vpc_config {
    security_group_ids = contains(["default", "disconnect"], each.value) ? [aws_security_group.ecs.id] : []
    subnet_ids         = contains(["default", "disconnect"], each.value) ? [var.ecs_subnet_id] : []
  }
  depends_on = [aws_cloudwatch_log_group.ws_handler]
  tags       = var.tags
}

# AUTHZ

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "ws_authz" {
  name              = "/aws/lambda/${local.cluster_name}_ws_authz"
  retention_in_days = 3
  tags              = var.tags
}

data "aws_iam_policy_document" "ws_authz_logs" {
  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.ws_authz.arn}:*"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "ws_authz_logs" {
  name   = "${var.svc_name}-ws-authz-logs"
  policy = data.aws_iam_policy_document.ws_authz_logs.json
  tags   = var.tags
}

resource "aws_iam_role" "ws_authz" {
  assume_role_policy  = data.aws_iam_policy_document.assume_role.json
  managed_policy_arns = [aws_iam_policy.ws_authz_logs.arn]
  tags                = var.tags
}

data "archive_file" "ws_authz" {
  type        = "zip"
  source_file = "${path.module}/src/ws_authz.py"
  output_path = "${path.module}/src/ws_authz_payload.zip"
}

resource "aws_lambda_function" "ws_authz" {
  filename         = data.archive_file.ws_authz.output_path
  function_name    = "${local.cluster_name}_ws_authz"
  role             = aws_iam_role.ws_authz.arn
  handler          = "ws_authz.do"
  source_code_hash = data.archive_file.ws_authz.output_base64sha256
  runtime          = "python3.10"
  tracing_config {
    mode = "PassThrough" #tfsec:ignore:aws-lambda-enable-tracing
  }
  depends_on = [aws_cloudwatch_log_group.ws_authz]
  tags       = var.tags
}
