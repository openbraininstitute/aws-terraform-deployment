# Subnets for the SBO core svc
resource "aws_subnet" "core_svc_a" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${data.aws_region.current.name}a"
  cidr_block              = "10.0.5.0/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_svc"
    SBO_Billing = "core_svc"
  }
}

resource "aws_subnet" "core_svc_b" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${data.aws_region.current.name}b"
  cidr_block              = "10.0.5.16/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_svc"
    SBO_Billing = "core_svc"
  }
}


# Link route table to core_svc network
resource "aws_route_table_association" "core_svc_a" {
  subnet_id      = aws_subnet.core_svc_a.id
  route_table_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}

resource "aws_route_table_association" "core_svc_b" {
  subnet_id      = aws_subnet.core_svc_b.id
  route_table_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}

resource "aws_network_acl" "core_svc" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.core_svc_a.id, aws_subnet.core_svc_b.id]
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
