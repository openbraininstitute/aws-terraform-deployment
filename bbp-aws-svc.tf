# https://docs.aws.amazon.com/apigateway/latest/developerguide/set-up-logging.html#set-up-access-logging-using-console
data "aws_iam_policy_document" "apigw" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "apigw_cloudwatch" {
  name                = "api-gateway-cloudwatch-global"
  assume_role_policy  = data.aws_iam_policy_document.apigw.json
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"]
}

resource "aws_api_gateway_account" "this" {
  cloudwatch_role_arn = aws_iam_role.apigw_cloudwatch.arn
}

# Demo on-demand service
module "on_demand_svc" {
  source              = "./on_demand_svc"
  svc_name            = "bbp-aws-svc"
  vpc_id              = data.terraform_remote_state.common.outputs.vpc_id
  aws_region          = var.aws_region
  ec2_subnet_id       = aws_subnet.bbp_aws_svc_ec2.id
  ec2_image_id        = data.aws_ami.amazon_linux_2_ecs.id
  ecs_subnet_id       = aws_subnet.bbp_aws_svc_ecs.id
  dockerhub_creds_arn = data.terraform_remote_state.common.outputs.dockerhub_credentials_arn
  account_id          = data.aws_caller_identity.current.account_id
  svc_image           = "bluebrain/bbp-aws-svc:latest"
  svc_bucket          = "sbo-cell-svc-perf-test"
  tags                = { SBO_Billing = "bbp_aws_svc" }
}
