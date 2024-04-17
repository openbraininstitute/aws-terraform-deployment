resource "aws_subnet" "ml_subnet_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.4.0/24"
  tags              = var.tags
}

resource "aws_route_table_association" "ml_rta_a" {
  subnet_id      = aws_subnet.ml_subnet_a.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_network_acl" "ml_acl_a" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.ml_subnet_a.id]
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
  tags = var.tags
}

resource "aws_subnet" "ml_subnet_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.27.0/24"
  tags              = var.tags
}

resource "aws_route_table_association" "ml_rta_b" {
  subnet_id      = aws_subnet.ml_subnet_b.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_network_acl" "ml_acl_b" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.ml_subnet_b.id]
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
  tags = var.tags
}
