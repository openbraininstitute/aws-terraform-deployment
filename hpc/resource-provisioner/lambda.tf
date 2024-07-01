data "aws_ecr_image" "hpc_resource_provisioner_image" {
  repository_name = "hpc-resource-provisioner"
  image_tag       = "latest"
}

resource "aws_lambda_permission" "hpc_resource_provisioner_permission_post" {
  statement_id  = "AllowAPIGatewayInvokePOST"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hpc_resource_provisioner_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.hpc_resource_provisioner_api.id}/*"
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "hpc_resource_provisioner_lambda" {
  function_name    = "hpc-resource-provisioner"
  role             = var.hpc_resource_provisioner_role
  image_uri        = var.hpc_resource_provisioner_image_uri
  package_type     = "Image"
  architectures    = ["x86_64"]
  timeout          = 90
  memory_size      = 1024
  source_code_hash = trimprefix(data.aws_ecr_image.hpc_resource_provisioner_image.id, "sha256:")
  vpc_config {
    security_group_ids = var.hpc_resource_provisioner_sg_ids
    subnet_ids         = var.hpc_resource_provisioner_subnet_ids
  }
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "hpc_resource_provisioner_async_lambda" {
  function_name    = "hpc-resource-provisioner-creator"
  role             = var.hpc_resource_provisioner_role
  image_uri        = var.hpc_resource_provisioner_image_uri
  package_type     = "Image"
  architectures    = ["x86_64"]
  timeout          = 300
  memory_size      = 1024
  source_code_hash = trimprefix(data.aws_ecr_image.hpc_resource_provisioner_image.id, "sha256:")
  image_config {
    command = ["hpc_provisioner.handlers.pcluster_do_create_handler"]
  }
  vpc_config {
    security_group_ids = var.hpc_resource_provisioner_sg_ids
    subnet_ids         = var.hpc_resource_provisioner_subnet_ids
  }
}
