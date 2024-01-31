# Subnet for the Nexus Delta application
resource "aws_subnet" "nexus_app" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.32/28"
  tags = {
    Name        = "nexus_app"
    SBO_Billing = "nexus"
  }
}

# Route table for the nexus_app network
resource "aws_route_table" "nexus_app" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
  tags = {
    Name        = "nexus_app_route"
    SBO_Billing = "nexus"
  }
}

# Link route table to nexus_app network
resource "aws_route_table_association" "nexus_app" {
  subnet_id      = aws_subnet.nexus_app.id
  route_table_id = aws_route_table.nexus_app.id
}

resource "aws_network_acl" "nexus_app" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.nexus_app.id]
  # Allow local traffic
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
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
    Name        = "nexus_app_acl"
    SBO_Billing = "nexus"
  }
}

# Subnet for the Nexus blazegraph
resource "aws_subnet" "blazegraph_app" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.80/28"
  tags = {
    Name        = "blazegraph_app"
    SBO_Billing = "nexus"
  }
}

resource "aws_route_table" "blazegraph_app" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
  tags = {
    Name        = "blazegraph_app_route"
    SBO_Billing = "nexus"
  }
}

resource "aws_route_table_association" "blazegraph_app" {
  subnet_id      = aws_subnet.blazegraph_app.id
  route_table_id = aws_route_table.blazegraph_app.id
}

resource "aws_network_acl" "blazegraph" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.blazegraph_app.id]
  # TODO limit to nexus subnets + correct ports
  ingress {
    protocol   = -1
    rule_no    = 101
    action     = "allow"
    cidr_block = var.vpc_cidr_block
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
    # TODO limit to dockerhub, secretsmanager, nexus...
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "blazegraph_acl"
    SBO_Billing = "nexus"
  }
}
