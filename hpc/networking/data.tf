data "aws_vpc" "pcluster_vpc" {
  id = var.pcluster_vpc_id
}

data "aws_vpc" "obp_vpc" {
  id = var.obp_vpc_id
}
