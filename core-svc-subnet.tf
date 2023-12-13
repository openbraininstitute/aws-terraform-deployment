# Subnet for the SBO core svc
resource "aws_subnet" "core_svc" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_svc"
    SBO_Billing = "core_svc"
  }
}

# Route table for the core_svc network
resource "aws_route_table" "core_svc" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "core_svc_route"
    SBO_Billing = "core_svc"
  }
}
# Link route table to core_svc network
resource "aws_route_table_association" "core_svc" {
  subnet_id      = aws_subnet.core_svc.id
  route_table_id = aws_route_table.core_svc.id
}

resource "aws_network_acl" "core_svc" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.core_svc.id]
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
    Name        = "core_svc_acl"
    SBO_Billing = "core_svc"
  }
}