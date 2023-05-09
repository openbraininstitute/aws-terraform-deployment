# Subnet for the SBO core webapp
# 10.0.2.0/28 is 10.0.2.0 up to 10.0.2.15 with subnet and broadcast included
resource "aws_subnet" "core_webapp" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.0/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_webapp"
    SBO_Billing = "core_webapp"
  }
}

# Route table for the core_webapp network
resource "aws_route_table" "core_webapp" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "core_webapp_route"
    SBO_Billing = "core_webapp"
  }
}
# Link route table to core_webapp network
resource "aws_route_table_association" "core_webapp" {
  subnet_id      = aws_subnet.core_webapp.id
  route_table_id = aws_route_table.core_webapp.id
}

resource "aws_network_acl" "core_webapp" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.core_webapp.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
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
    Name        = "core_webapp_acl"
    SBO_Billing = "core_webapp"
  }
}