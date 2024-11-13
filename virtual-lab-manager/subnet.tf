# Subnets for the SBO core svc
resource "aws_subnet" "virtual_lab_manager_a" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.11.0/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "virtual_lab_manager_subnet_a"
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_subnet" "virtual_lab_manager_b" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}b"
  cidr_block              = "10.0.11.16/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "virtual_lab_manager_subnet_b"
    SBO_Billing = "virtual_lab_manager"
  }
}


# Link route table to core_svc network
resource "aws_route_table_association" "virtual_lab_manager_a" {
  subnet_id      = aws_subnet.virtual_lab_manager_a.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_route_table_association" "virtual_lab_manager_b" {
  subnet_id      = aws_subnet.virtual_lab_manager_b.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_network_acl" "core_svc" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.virtual_lab_manager_a.id, aws_subnet.virtual_lab_manager_b.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  /* # Allow temporarily all
  ingress {
    protocol = -1
    rule_no = 101
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }*/
  # Allow port 8000 from anywhere
  # TODO limit to just ALB?
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8000
    to_port    = 8000
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
    Name        = "virtual_lab_manager_acl"
    SBO_Billing = "virtual_lab_manager"
  }
}
