locals {
  sandbox_resource_count = var.viz_enable_sandbox ? 1 : 0
}

resource "aws_vpc" "viz_sandbox" {
  count                = local.sandbox_resource_count
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
  tags = {
    Name = "viz_sandbox"
  }
}

data "aws_vpc" "selected" {
  id = var.viz_enable_sandbox ? aws_vpc.viz_sandbox[0].id : var.vpc_id
}

resource "aws_eip" "nat_eip" {
  count = local.sandbox_resource_count
}

resource "aws_internet_gateway" "ig" {
  count  = local.sandbox_resource_count
  vpc_id = aws_vpc.viz_sandbox[0].id
}

resource "aws_nat_gateway" "viz_sandbox" {
  count         = local.sandbox_resource_count
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.viz_public_a[0].id
}

data "aws_nat_gateway" "selected" {
  id = var.viz_enable_sandbox ? aws_nat_gateway.viz_sandbox[0].id : var.nat_gateway_id
}
