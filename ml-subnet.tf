# Subnet for Machine Learning
# 10.0.3.0/28 is 10.0.3.0 up to 10.0.3.15 with subnet and broadcast included
resource "aws_subnet" "machinelearning" {
  vpc_id                  = aws_vpc.sbo_poc.id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.3.0/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "machinelearning"
    SBO_Billing = "machinelearning"
  }
}

# Route table for the machinelearning network
resource "aws_route_table" "machinelearning" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name        = "machinelearning_route"
    SBO_Billing = "machinelearning"
  }
}
# Link route table to machinelearning network
resource "aws_route_table_association" "machinelearning" {
  subnet_id      = aws_subnet.machinelearning.id
  route_table_id = aws_route_table.machinelearning.id
}

resource "aws_network_acl" "machinelearning" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.machinelearning.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
    from_port  = 0
    to_port    = 0
  }
  # Allow port 80 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  egress {
    # TODO limit to dockerhub, secretsmanager, nexus...
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "machinelearning_acl"
  }
}