# This public subnet should exist only for environments like sandbox.
# It creates a public subnet that contains a nat gateway and attaches an
# internet gateway to the VPC.

# This subnet can be reached from the internet.
# The other subnets should allow at most inbound traffic from the VPC; this is
# handled by the security group.

# To deploy this, simply set the nat_gateway_id variable to ""

locals {
  create_nat_gateway = var.nat_gateway_id == "" ? true : false
}

resource "aws_subnet" "public_subnet" {
  count      = local.create_nat_gateway ? 1 : 0
  vpc_id     = var.vpc_id
  cidr_block = "10.0.3.48/28"
}

resource "aws_nat_gateway" "nat_gateway" {
  count         = local.create_nat_gateway ? 1 : 0
  allocation_id = aws_eip.nat_eip[0].id
  subnet_id     = aws_subnet.public_subnet[0].id
}

resource "aws_eip" "nat_eip" {
  count = local.create_nat_gateway ? 1 : 0
  vpc   = true
}

resource "aws_route_table" "public_route_table" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = var.vpc_id
}

resource "aws_route" "nexus_igw_route" {
  count                  = local.create_nat_gateway ? 1 : 0
  route_table_id         = aws_route_table.public_route_table[0].id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.nexus_ig[0].id
}

# Link route table to nexus_app network
resource "aws_route_table_association" "public_rt_association" {
  count          = local.create_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.public_subnet[0].id
  route_table_id = aws_route_table.public_route_table[0].id
}

resource "aws_internet_gateway" "nexus_ig" {
  count  = local.create_nat_gateway ? 1 : 0
  vpc_id = var.vpc_id
  tags = {
    Name        = "nexus_ig"
    SBO_Billing = "nexus"
  }
}