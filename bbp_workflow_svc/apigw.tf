data "aws_apigatewayv2_api" "this" {
  api_id = aws_apigatewayv2_api.this.id
}

# resource "aws_apigatewayv2_api" "this" {
#   name          = "bbp-workflow-svc"
#   protocol_type = "HTTP"
# }

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

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "apigw" {
  name              = "/aws/apigateway/${data.aws_apigatewayv2_api.this.id}"
  retention_in_days = 3
  tags              = var.tags
}

#tfsec:ignore:aws-cloudwatch-log-group-customer-key
# resource "aws_cloudwatch_log_group" "apigw_access_log" {
#   name              = "/aws/apigateway/${local.cluster_name}_access_log"
#   retention_in_days = 3
#   tags              = var.tags
# }

#tfsec:ignore:aws-api-gateway-enable-access-logging
resource "aws_apigatewayv2_stage" "this" {
  api_id      = data.aws_apigatewayv2_api.this.id
  name        = "${"$"}default"
  auto_deploy = true
  default_route_settings {
    detailed_metrics_enabled = true
    # data_trace_enabled     = true
    # logging_level          = "INFO"
    throttling_burst_limit = 10
    throttling_rate_limit  = 12
  }
  # access_log_settings {
  #   destination_arn = resource.aws_cloudwatch_log_group.apigw_access_log.arn
  #   format = jsonencode({
  #     requestId   = "$context.requestId"
  #     ip          = "$context.identity.sourceIp"
  #     requestTime = "$context.requestTime"
  #     routeKey    = "$context.routeKey"
  #     status      = "$context.status"
  #   })
  # }
  tags = var.tags
}

resource "aws_iam_role" "invoke_authz_token" {
  name               = "${var.svc_name}-apigw-invoke-authz-token"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-authz-token"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.authz_token.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_authorizer" "token" {
  api_id                     = data.aws_apigatewayv2_api.this.id
  authorizer_type            = "REQUEST"
  authorizer_uri             = aws_lambda_function.authz_token.invoke_arn
  authorizer_credentials_arn = aws_iam_role.invoke_authz_token.arn
  identity_sources           = ["$request.header.Authorization"]
  # authorizer_result_ttl_in_seconds  = 0
  authorizer_payload_format_version = "2.0"
  name                              = "authz-token"
  depends_on                        = [aws_cloudwatch_log_group.apigw]
}

resource "aws_iam_role" "invoke_authz_cookie" {
  name               = "${var.svc_name}-apigw-invoke-authz-cookie"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-authz-cookie"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.authz_cookie.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_authorizer" "cookie" {
  api_id                            = data.aws_apigatewayv2_api.this.id
  authorizer_type                   = "REQUEST"
  authorizer_uri                    = aws_lambda_function.authz_cookie.invoke_arn
  authorizer_credentials_arn        = aws_iam_role.invoke_authz_cookie.arn
  identity_sources                  = ["$request.header.Cookie"]
  authorizer_result_ttl_in_seconds  = 0
  authorizer_payload_format_version = "2.0"
  name                              = "authz-cookie"
  depends_on                        = [aws_cloudwatch_log_group.apigw]
}

resource "aws_iam_role" "invoke_handler_cors" {
  name               = "${var.svc_name}-apigw-invoke-handler-cors"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-handler-cors"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.handler_cors.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "cors" {
  api_id             = data.aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.invoke_handler_cors.arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.handler_cors.invoke_arn
}

resource "aws_apigatewayv2_route" "cors" {
  api_id    = data.aws_apigatewayv2_api.this.id
  route_key = "OPTIONS /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.cors.id}"
}

resource "aws_iam_role" "invoke_handler_session" {
  name               = "${var.svc_name}-apigw-invoke-handler-session"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-handler-session"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.handler_session.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "session" {
  api_id             = data.aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.invoke_handler_session.arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.handler_session.invoke_arn
}

# route_key = "ANY /example/{proxy+}"
resource "aws_apigatewayv2_route" "session" {
  api_id             = data.aws_apigatewayv2_api.this.id
  route_key          = "GET /session/{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.token.id
  target             = "integrations/${aws_apigatewayv2_integration.session.id}"
}

resource "aws_iam_role" "invoke_handler_auth" {
  name               = "${var.svc_name}-apigw-invoke-handler-auth"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-handler-auth"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.handler_auth.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "auth" {
  api_id             = data.aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.invoke_handler_auth.arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.handler_auth.invoke_arn
}

resource "aws_apigatewayv2_route" "auth" {
  api_id             = data.aws_apigatewayv2_api.this.id
  route_key          = "GET /auth/{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.cookie.id
  target             = "integrations/${aws_apigatewayv2_integration.auth.id}"
}

resource "aws_iam_role" "invoke_handler_launch" {
  name               = "${var.svc_name}-apigw-invoke-handler-launch"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-handler-launch"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.handler_launch.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "launch" {
  api_id             = data.aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.invoke_handler_launch.arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.handler_launch.invoke_arn
}

resource "aws_apigatewayv2_route" "launch" {
  api_id             = data.aws_apigatewayv2_api.this.id
  route_key          = "POST /launch/{proxy+}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.cookie.id
  target             = "integrations/${aws_apigatewayv2_integration.launch.id}"
}

resource "aws_iam_role" "invoke_handler_default" {
  name               = "${var.svc_name}-apigw-invoke-handler-default"
  assume_role_policy = data.aws_iam_policy_document.apigw.json
  inline_policy {
    name = "${var.svc_name}-apigw-invoke-handler-default"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Action   = ["lambda:InvokeFunction"]
        Effect   = "Allow"
        Resource = aws_lambda_function.handler_default.arn
      }]
    })
  }
  tags = var.tags
}

resource "aws_apigatewayv2_integration" "default" {
  api_id             = data.aws_apigatewayv2_api.this.id
  connection_type    = "INTERNET"
  credentials_arn    = aws_iam_role.invoke_handler_default.arn
  integration_method = "POST"
  integration_type   = "AWS_PROXY"
  integration_uri    = aws_lambda_function.handler_default.invoke_arn
}

resource "aws_apigatewayv2_route" "default" {
  api_id             = data.aws_apigatewayv2_api.this.id
  route_key          = "${"$"}default"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.cookie.id
  target             = "integrations/${aws_apigatewayv2_integration.default.id}"
}

# resource "aws_apigatewayv2_route_response" "handler_default" {
#   api_id             = aws_apigatewayv2_api.this.id
#   route_id           = aws_apigatewayv2_route.handler_default.id
#   route_response_key = "$default"
# }
