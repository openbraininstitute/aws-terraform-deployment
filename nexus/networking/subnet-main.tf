# Subnet for Nexus
resource "aws_subnet" "nexus_main" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.9.0/24"
  tags = {
    Name        = "nexus_main_subnet"
    SBO_Billing = "nexus"
  }
}

# TODO: Old subnet to be deleted once unused
resource "aws_subnet" "nexus" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.32/28"
  tags = {
    Name        = "nexus_subnet"
    SBO_Billing = "nexus"
  }
}

# Route table for the Nexus network
resource "aws_route_table" "nexus" {
  vpc_id = var.vpc_id
  tags = {
    Name        = "nexus_route"
    SBO_Billing = "nexus"
  }
}

locals {
  nat_gateway_id = var.nat_gateway_id != "" ? var.nat_gateway_id : aws_nat_gateway.nat_gateway[0].id
}

resource "aws_route" "nexus_nat_route" {
  route_table_id         = aws_route_table.nexus.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = local.nat_gateway_id
}

# Link route table to nexus_app network
resource "aws_route_table_association" "nexus" {
  subnet_id      = aws_subnet.nexus_main.id
  route_table_id = aws_route_table.nexus.id
}

resource "aws_network_acl" "nexus" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.nexus_main.id]
  # Allow local traffic
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.provided_vpc.cidr_block
    from_port  = 0
    to_port    = 0
  }
  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  # TODO the ssh access needs to be configurable so that it can be disabled
  # allow ssh access
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  egress {
    # TODO setup limits.
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "nexus_acl"
    SBO_Billing = "nexus"
  }
}