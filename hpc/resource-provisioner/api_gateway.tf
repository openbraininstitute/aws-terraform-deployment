resource "aws_api_gateway_rest_api" "hpc_resource_provisioner_api" {
  name = "hpc_resource_provisioner"
}

resource "aws_api_gateway_resource" "hpc_resource_provisioner_res_provisioner" {
  rest_api_id = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  parent_id   = aws_api_gateway_rest_api.hpc_resource_provisioner_api.root_resource_id
  path_part   = "hpc-provisioner"
}

resource "aws_api_gateway_resource" "hpc_resource_provisioner_res_pcluster" {
  rest_api_id = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  parent_id   = aws_api_gateway_resource.hpc_resource_provisioner_res_provisioner.id
  path_part   = "pcluster"
}

resource "aws_api_gateway_resource" "hpc_resource_provisioner_res_version" {
  rest_api_id = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  parent_id   = aws_api_gateway_resource.hpc_resource_provisioner_res_provisioner.id
  path_part   = "version"
}

locals {
  http_methods = ["GET", "POST", "DELETE"]
}

resource "aws_api_gateway_method" "hpc_resource_provisioner_pcluster_method" {
  rest_api_id   = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  resource_id   = aws_api_gateway_resource.hpc_resource_provisioner_res_pcluster.id
  count         = 3
  http_method   = local.http_methods[count.index]
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_method" "hpc_resource_provisioner_version_method" {
  rest_api_id   = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  resource_id   = aws_api_gateway_resource.hpc_resource_provisioner_res_version.id
  http_method   = "GET"
  authorization = "AWS_IAM"
}

resource "aws_api_gateway_integration" "hpc_resource_provisioner_pcluster_integration" {
  count                   = 3
  rest_api_id             = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  resource_id             = aws_api_gateway_resource.hpc_resource_provisioner_res_pcluster.id
  http_method             = aws_api_gateway_method.hpc_resource_provisioner_pcluster_method[count.index].http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hpc_resource_provisioner_lambda.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_integration" "hpc_resource_provisioner_version_integration" {
  rest_api_id             = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  resource_id             = aws_api_gateway_resource.hpc_resource_provisioner_res_version.id
  http_method             = aws_api_gateway_method.hpc_resource_provisioner_version_method.http_method
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.hpc_resource_provisioner_lambda.invoke_arn
  integration_http_method = "POST"
}

resource "aws_api_gateway_deployment" "hpc_resource_provisioner_api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  triggers = {
    # redeploy when the api or its methods change, but also serves to declare a dependency
    # if omitted, terraform may deploy the deployment before the methods
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.hpc_resource_provisioner_api.body,
      aws_api_gateway_method.hpc_resource_provisioner_pcluster_method[*].id,
      aws_lambda_function.hpc_resource_provisioner_lambda
    ]))
  }
}

# tfsec:ignore:aws-api-gateway-enable-tracing tfsec:ignore:aws-api-gateway-enable-access-logging
resource "aws_api_gateway_stage" "hpc_resource_provisioner_api_stage" {
  rest_api_id   = aws_api_gateway_rest_api.hpc_resource_provisioner_api.id
  stage_name    = "production"
  deployment_id = aws_api_gateway_deployment.hpc_resource_provisioner_api_deployment.id
  lifecycle {
    replace_triggered_by = [
      aws_api_gateway_deployment.hpc_resource_provisioner_api_deployment
    ]
  }
}
