# The virtual private cloud containing all the subnets
# TODO: some issue with the tfsec check? no such option to enable flow logs
#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "sbo_poc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name        = "sbo_poc"
    SBO_Billing = "common"
  }
}
