resource "aws_iam_user" "bbp_workflow_service_user" {
  name = "bbp-workflow-service-user"
  tags = {
    SBO_Billing = "workflow"
  }
}

data "aws_iam_policy" "AmazonAPIGatewayInvokeFullAccess" {
  arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayInvokeFullAccess"
}

resource "aws_iam_user_policy_attachment" "AmazonAPIGatewayInvokeFullAccess_attach" {
  user       = aws_iam_user.bbp_workflow_service_user.name
  policy_arn = data.aws_iam_policy.AmazonAPIGatewayInvokeFullAccess.arn
}
