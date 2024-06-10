# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "hpc_resource_provisioner_creator_log_group" {
  name              = "/aws/lambda/hpc-resource-provisioner-creator"
  retention_in_days = 7
}
# tfsec:ignore:aws-cloudwatch-log-group-customer-key
resource "aws_cloudwatch_log_group" "hpc_resource_provisioner_log_group" {
  name              = "/aws/lambda/hpc-resource-provisioner"
  retention_in_days = 7
}
