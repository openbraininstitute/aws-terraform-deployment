# Subnet for bbp-workflow
# 10.0.3.16/28 is 10.0.3.16 up to 10.0.3.31 with subnet and broadcast included
resource "aws_subnet" "workflow" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.3.16/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "workflow"
    SBO_Billing = "workflow"
  }
}


# Link route table to bbp-workflow network
resource "aws_route_table_association" "workflow" {
  subnet_id      = aws_subnet.workflow.id
  route_table_id = data.terraform_remote_state.common.outputs.route_table_private_subnets_id
}

resource "aws_network_acl" "workflow" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.workflow.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  # Allow port 8100 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8100
    to_port    = 8100
  }
  # Allow port 8082 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 106
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8082
    to_port    = 8082
  }
  # Allow port 8080 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 107
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 8080
    to_port    = 8080
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
    Name        = "workflow_acl"
    SBO_Billing = "workflow"
  }
}
