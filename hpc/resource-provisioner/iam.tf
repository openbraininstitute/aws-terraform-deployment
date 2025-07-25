resource "aws_iam_role" "resource_provisioner_eventbridge" {
  name               = "hpc_resource_provisioner_eventbridge_role"
  assume_role_policy = file("${path.module}/hpc_resource_provisioner_eventbridge_assume_role_policy.json")
}

resource "aws_iam_role_policy_attachment" "resource_provisioner_eventbridge" {
  role       = aws_iam_role.resource_provisioner_eventbridge.name
  policy_arn = aws_iam_policy.resource_provisioner_eventbridge.arn
}

resource "aws_iam_policy" "resource_provisioner_eventbridge" {
  name   = "eventbridge_fire_lambda_policy"
  policy = templatefile("${path.module}/hpc_resource_provisioner_eventbridge_policy.tftpl", { "account_id" = var.account_id, "aws_region" = var.aws_region, "api_deployment_id" = aws_api_gateway_deployment.hpc_resource_provisioner_api_deployment.id })
}

