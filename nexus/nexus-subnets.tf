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

resource "aws_subnet" "nexus_es_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.96/28"
  tags = {
    Name        = "nexus_es_a"
    SBO_Billing = "nexus"
  }
}

resource "aws_subnet" "nexus_es_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.2.112/28"
  tags = {
    Name        = "nexus_es_b"
    SBO_Billing = "nexus"
  }
}

resource "aws_route_table" "nexus_es" {
  vpc_id = var.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = var.nat_gateway_id
  }
  tags = {
    Name        = "nexus_es_route"
    SBO_Billing = "nexus"
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
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.nexus_es_a.id, aws_subnet.nexus_es_b.id]
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
    # TODO probably not needed
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "nexus_es_acl"
    SBO_Billing = "nexus"
  }
}

resource "aws_security_group" "nexus_db" {
  name   = "nexus_db"
  vpc_id = var.vpc_id

  description = "Nexus PostgreSQL database"
  # Only PostgreSQL traffic inbound
  /*ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.nexus_app.id]
  }*/
  # for testing allow everything TODO
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow ingress from within vpc"
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow egress to within vpc"
  }
  tags = {
    SBO_Billing = "nexus"
  }
}


