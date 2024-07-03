# ################################################################################
# How to setup NAT
# ################################################################################
#
resource "aws_eip" "compute_eip" {
  domain = "vpc"
  count  = var.compute_nat_access ? 1 : 0
}

resource "aws_nat_gateway" "compute_gw" {
  allocation_id     = one(aws_eip.compute_eip[*].id)
  count             = var.compute_nat_access ? 1 : 0
  connectivity_type = "public"
  subnet_id         = local.aws_subnet_public_id
}

resource "aws_route" "compute_nat" {
  route_table_id         = aws_route_table.compute.id
  count                  = var.compute_nat_access ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = one(aws_nat_gateway.compute_gw[*].id)
}
#
# ################################################################################
