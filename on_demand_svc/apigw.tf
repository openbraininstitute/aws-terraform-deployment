resource "aws_apigatewayv2_api" "this" {
  name                       = var.svc_name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = "\\$default"
  tags                       = var.tags
}

resource "aws_apigatewayv2_authorizer" "this" {
  api_id                     = aws_apigatewayv2_api.this.id
  authorizer_type            = "REQUEST"
  authorizer_uri             = aws_lambda_function.ws_authz.invoke_arn
  authorizer_credentials_arn = aws_iam_role.invoke_ws_authz.arn
  identity_sources           = ["route.request.header.Authorization"]
  name                       = "ws_authz"
  depends_on                 = [aws_cloudwatch_log_group.apigw]
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.this.id}/${aws_apigatewayv2_stage.prod.name}"
  retention_in_days = 1
  tags              = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "apigw_access_log" {
  name              = "/aws/apigateway/${local.cluster_name}_access_log"
  retention_in_days = 1
  tags              = var.tags
}

data "aws_iam_policy_document" "apigw" {
  statement {
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
  }
}

data "aws_iam_policy_document" "invoke_ws_handler" {
  for_each = var.actions
  statement {
    resources = [aws_lambda_function.ws_handler[each.key].arn]
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "invoke_ws_handler" {
  for_each = var.actions
  policy   = data.aws_iam_policy_document.invoke_ws_handler[each.key].json
  tags     = var.tags
}

data "aws_iam_policy_document" "invoke_ws_authz" {
  statement {
    resources = [aws_lambda_function.ws_authz.arn]
    actions   = ["lambda:InvokeFunction"]
    effect    = "Allow"
  }
}

resource "aws_iam_policy" "invoke_ws_authz" {
  name   = "${var.svc_name}-apigw-invoke-ws-authz"
  policy = data.aws_iam_policy_document.invoke_ws_authz.json
  tags   = var.tags
}

resource "aws_iam_role" "invoke_ws_authz" {
  name                = "${var.svc_name}-apigw-invoke-ws-authz"
  assume_role_policy  = data.aws_iam_policy_document.apigw.json
  managed_policy_arns = [aws_iam_policy.invoke_ws_authz.arn]
  tags                = var.tags
}

resource "aws_iam_role" "apigw" {
  for_each            = var.actions
  assume_role_policy  = data.aws_iam_policy_document.apigw.json
  managed_policy_arns = [aws_iam_policy.invoke_ws_handler[each.key].arn]
  tags                = var.tags
}

resource "aws_apigatewayv2_integration" "ws_handler" {
  for_each           = var.actions
  api_id             = aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.apigw[each.key].arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.ws_handler[each.key].invoke_arn
}

resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "prod"
  auto_deploy = true
  default_route_settings {
    data_trace_enabled     = true
    logging_level          = "INFO"
    throttling_burst_limit = 1
    throttling_rate_limit  = 2
  }
  access_log_settings {
    destination_arn = resource.aws_cloudwatch_log_group.apigw_access_log.arn
    format          = "{\"requestId\":\"$context.requestId\", \"ip\": \"$context.identity.sourceIp\", \"requestTime\":\"$context.requestTime\", \"routeKey\":\"$context.routeKey\", \"status\":\"$context.status\"}"
  }
  tags = var.tags
}

resource "aws_apigatewayv2_route" "ws_handler" {
  for_each           = var.actions
  api_id             = aws_apigatewayv2_api.this.id
  route_key          = "${"$"}${each.value}"
  authorization_type = each.value == "connect" ? "CUSTOM" : null
  authorizer_id      = each.value == "connect" ? aws_apigatewayv2_authorizer.this.id : null
  target             = "integrations/${aws_apigatewayv2_integration.ws_handler[each.key].id}"
}

resource "aws_apigatewayv2_route_response" "default" {
  api_id             = aws_apigatewayv2_api.this.id
  route_id           = aws_apigatewayv2_route.ws_handler["default"].id
  route_response_key = "$default"
}
