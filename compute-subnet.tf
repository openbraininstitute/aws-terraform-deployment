# Subnet for compute nodes
resource "aws_subnet" "compute" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.32.0/21"
  tags = {
    Name        = "compute"
    SBO_Billing = "common"
  }
}

# Route table for the compute network
resource "aws_route_table" "compute" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name        = "compute_route"
    SBO_Billing = "common"
  }
}

# Link route table to compute network
resource "aws_route_table_association" "compute" {
  subnet_id      = aws_subnet.compute.id
  route_table_id = aws_route_table.compute.id
}

resource "aws_network_acl" "compute" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.compute.id]
  # Allow local traffic
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
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
    Name        = "compute_acl"
    SBO_Billing = "common"
  }
}
