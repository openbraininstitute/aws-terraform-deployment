# Subnet for viz
resource "aws_subnet" "viz" {
  vpc_id                  = data.aws_vpc.selected.id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.176/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "viz"
    SBO_Billing = "viz"
  }
}

# Subnet for the databases and storage
resource "aws_subnet" "viz_db_a" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.40.0/28"
  tags = {
    Name        = "viz_db_a"
    SBO_Billing = "viz"
  }
}
# Subnet for the databases and storage
resource "aws_subnet" "viz_db_b" {
  vpc_id            = data.aws_vpc.selected.id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.40.16/28"
  tags = {
    Name        = "viz_db_b"
    SBO_Billing = "viz"
  }
}


# Route table for the viz network
resource "aws_route_table" "viz" {
  vpc_id = data.aws_vpc.selected.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.selected.id
  }
  tags = {
    Name        = "viz_route"
    SBO_Billing = "viz"
  }
}
## Link route table to viz network
resource "aws_route_table_association" "viz" {
  subnet_id      = aws_subnet.viz.id
  route_table_id = aws_route_table.viz.id
}

resource "aws_network_acl" "viz" {
  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = [aws_subnet.viz.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.selected.cidr_block
    from_port  = 0
    to_port    = 0
  }
  # allow ingress ephemeral ports: otherwise ECS can't reach dockerhub
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
    Name        = "viz_acl"
    SBO_Billing = "viz"
  }
}


#
## Route table for the viz db networks
resource "aws_route_table" "viz_db" {
  vpc_id = data.aws_vpc.selected.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.aws_nat_gateway.selected.id

  }
  tags = {
    Name        = "viz_db_route"
    SBO_Billing = "viz"
  }
}

# Link route table to viz db networks
resource "aws_route_table_association" "viz_db_a" {
  subnet_id      = aws_subnet.viz_db_a.id
  route_table_id = aws_route_table.viz_db.id
}

resource "aws_route_table_association" "viz_db_b" {
  subnet_id      = aws_subnet.viz_db_b.id
  route_table_id = aws_route_table.viz_db.id
}

resource "aws_network_acl" "viz_db" {
  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = [aws_subnet.viz_db_a.id, aws_subnet.viz_db_b.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.selected.cidr_block
    from_port  = 5432
    to_port    = 5432
  }
  # TODO: do we need it?
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = data.aws_vpc.selected.cidr_block
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.selected.cidr_block
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "nexus_viz_acl"
    SBO_Billing = "viz"
  }
}
