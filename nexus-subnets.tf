# Subnet for the Nexus Delta application
resource "aws_subnet" "nexus_app" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.32/28"
  tags = {
    Name = "nexus_app"
  }
}

# Route table for the nexus_app network
resource "aws_route_table" "nexus_app" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name = "nexus_app_route"
  }
}

# Link route table to nexus_app network
resource "aws_route_table_association" "nexus_app" {
  subnet_id      = aws_subnet.nexus_app.id
  route_table_id = aws_route_table.nexus_app.id
}

resource "aws_network_acl" "nexus_app" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.nexus_app.id]
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
    Name = "nexus_app_acl"
  }
}

# Subnet for the Nexus databases and storage
resource "aws_subnet" "nexus_db_a" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.48/28"
  tags = {
    Name = "nexus_db_a"
  }
}
# Subnet for the Nexus databases and storage
resource "aws_subnet" "nexus_db_b" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.2.64/28"
  tags = {
    Name = "nexus_db_b"
  }
}

# Route table for the nexus_db* networks
resource "aws_route_table" "nexus_db" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name = "nexus_db_route"
  }
}

resource "aws_route_table_association" "nexus_db_a" {
  subnet_id      = aws_subnet.nexus_db_a.id
  route_table_id = aws_route_table.nexus_db.id
}

resource "aws_route_table_association" "nexus_db_b" {
  subnet_id      = aws_subnet.nexus_db_b.id
  route_table_id = aws_route_table.nexus_db.id
}

resource "aws_network_acl" "nexus_db" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.nexus_db_a.id, aws_subnet.nexus_db_b.id]
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
    from_port  = 5432
    to_port    = 5432
  }
  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    # TODO can be removed? Or needs access to secrets manager?
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "nexus_db_acl"
  }
}

# Subnet for the Nexus blazegraph
resource "aws_subnet" "blazegraph_app" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.80/28"
  tags = {
    Name = "blazegraph_app"
  }
}

resource "aws_route_table" "blazegraph_app" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name = "blazegraph_app_route"
  }
}

resource "aws_route_table_association" "blazegraph_app" {
  subnet_id      = aws_subnet.blazegraph_app.id
  route_table_id = aws_route_table.blazegraph_app.id
}

resource "aws_network_acl" "blazegraph" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.blazegraph_app.id]
  # TODO limit to nexus subnets + correct ports
  ingress {
    protocol   = -1
    rule_no    = 101
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
    # TODO limit to dockerhub, secretsmanager, nexus...
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "blazegraph_acl"
  }
}

resource "aws_subnet" "nexus_es_a" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.96/28"
  tags = {
    Name = "nexus_es_a"
  }
}

resource "aws_subnet" "nexus_es_b" {
  vpc_id            = aws_vpc.sbo_poc.id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.2.112/28"
  tags = {
    Name = "nexus_es_b"
  }
}

resource "aws_route_table" "nexus_es" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name = "nexus_es_route"
  }
}

resource "aws_route_table_association" "nexus_es_a" {
  subnet_id      = aws_subnet.nexus_es_a.id
  route_table_id = aws_route_table.nexus_es.id
}

resource "aws_route_table_association" "nexus_es_b" {
  subnet_id      = aws_subnet.nexus_es_b.id
  route_table_id = aws_route_table.nexus_es.id
}

resource "aws_network_acl" "nexus_es" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.nexus_es_a.id, aws_subnet.nexus_es_b.id]
  # TODO limit to nexus subnets + correct ports
  ingress {
    protocol   = -1
    rule_no    = 101
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
    # TODO probably not needed
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name = "nexus_es_acl"
  }
}
