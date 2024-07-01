data "aws_vpc" "peering_vpc" {
  id = var.obp_vpc_id
}

data "aws_subnet" "endpoints_subnet" {
  id = var.endpoints_subnet_id
}
