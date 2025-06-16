resource "aws_lambda_permission" "hpc_resource_provisioner_permission_post" {
  statement_id  = "AllowAPIGatewayInvokePOST"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hpc_resource_provisioner_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "arn:aws:execute-api:${var.aws_region}:${var.account_id}:${aws_api_gateway_rest_api.hpc_resource_provisioner_api.id}/*"
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "hpc_resource_provisioner_lambda" {
  function_name    = "hpc-resource-provisioner-${var.suffix}"
  role             = var.hpc_resource_provisioner_role
  package_type     = "Image"
  architectures    = ["x86_64"]
  timeout          = 90
  memory_size      = 1024
  source_code_hash = trimprefix(data.aws_ecr_image.hpc_resource_provisioner_image.id, "sha256:")
  image_uri        = data.aws_ecr_image.hpc_resource_provisioner_image.image_uri
  vpc_config {
    security_group_ids = var.hpc_resource_provisioner_sg_ids
    subnet_ids         = var.hpc_resource_provisioner_subnet_ids
  }
  environment {
    variables = {
      SBO_NEXUSDATA_BUCKET = var.sbo_nexusdata_bucket
      CONTAINERS_BUCKET    = var.containers_bucket
      SCRATCH_BUCKET       = var.scratch_bucket
      SCRATCH_BUCKET_ARN   = var.scratch_bucket_arn
      EFA_SG_ID            = var.aws_security_group_efa_id
      FSX_POLICY_ARN       = var.fsx_policy_arn
      SUFFIX               = var.suffix
    }
  }
}

data "aws_ecr_image" "hpc_resource_provisioner_image" {
  repository_name = "hpc/resource-provisioner"
  image_tag       = var.hpc_resource_provisioner_container_version
}

# tfsec:ignore:aws-lambda-enable-tracing
resource "aws_lambda_function" "hpc_resource_provisioner_async_lambda" {
  function_name    = "hpc-resource-provisioner-creator-${var.suffix}"
  role             = var.hpc_resource_provisioner_role
  package_type     = "Image"
  architectures    = ["x86_64"]
  timeout          = 300
  memory_size      = 1024
  source_code_hash = trimprefix(data.aws_ecr_image.hpc_resource_provisioner_image.id, "sha256:")
  image_uri        = data.aws_ecr_image.hpc_resource_provisioner_image.image_uri
  image_config {
    command = ["hpc_provisioner.handlers.pcluster_do_create_handler"]
  }
  vpc_config {
    security_group_ids = var.hpc_resource_provisioner_sg_ids
    subnet_ids         = var.hpc_resource_provisioner_subnet_ids
  }
  environment {
    variables = {
      SBO_NEXUSDATA_BUCKET = var.sbo_nexusdata_bucket
      CONTAINERS_BUCKET    = var.containers_bucket
      SCRATCH_BUCKET       = var.scratch_bucket
      SCRATCH_BUCKET_ARN   = var.scratch_bucket_arn
      EFA_SG_ID            = var.aws_security_group_efa_id
      FSX_POLICY_ARN       = var.fsx_policy_arn
      FS_SUBNET_IDS        = jsonencode(var.fs_subnet_ids)
      FS_SG_ID             = var.fs_sg_id
      EVENTBRIDGE_ROLE_ARN = var.eventbridge_role_arn
      API_GW_STAGE_ARN     = aws_api_gateway_stage.hpc_resource_provisioner_api_stage.arn
      PCLUSTER_AMI_ID      = var.pcluster_ami_id
    }
  }
}
