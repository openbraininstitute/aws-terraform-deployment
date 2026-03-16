# Subnet for the core webapp
resource "aws_subnet" "core_webapp" {
  vpc_id                  = var.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = var.subnet_cidr_block
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_webapp"
    SBO_Billing = var.sbo_billing_tag
  }
}

# Link route table to core_webapp network
resource "aws_route_table_association" "core_webapp" {
  subnet_id      = aws_subnet.core_webapp.id
  route_table_id = var.route_table_id
}

resource "aws_network_acl" "core_webapp" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.core_webapp.id]
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = var.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 3389
    to_port    = 3389
  }
  ingress {
    protocol   = "tcp"
    rule_no    = 400
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "core_webapp_acl"
    SBO_Billing = var.sbo_billing_tag
  }
}
