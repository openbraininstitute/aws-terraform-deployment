resource "aws_subnet" "subnet" {
  vpc_id            = var.vpc_id
  availability_zone = "${data.aws_region.current.name}a"
  cidr_block        = var.subnet_cidr_block
  tags = {
    Name = var.subnet_name
  }
}

resource "aws_route_table_association" "subnet_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_network_acl" "network_acl" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.subnet.id]
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }
  ingress {
    protocol   = -1
    rule_no    = 106
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = var.vm_name
  }
}
