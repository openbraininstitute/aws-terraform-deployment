# Fetch the data for the provided VPC
data "aws_vpc" "provided_vpc" {
  id = var.vpc_id
}