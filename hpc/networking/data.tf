data "aws_vpc" "pcluster_vpc" {
  id = var.pcluster_vpc_id
}

data "aws_vpc" "obp_vpc" {
  id = var.obp_vpc_id
}

data "aws_route_table" "default_route_table" {
  vpc_id = var.pcluster_vpc_id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}
