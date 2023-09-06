# Subnet for viz
resource "aws_subnet" "viz" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.176/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "viz"
    SBO_Billing = "viz"
  }
}

# Route table for the viz network
resource "aws_route_table" "viz" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "viz_route"
    SBO_Billing = "viz"
  }
}

# Link route table to viz network
resource "aws_route_table_association" "viz" {
  subnet_id      = aws_subnet.viz.id
  route_table_id = aws_route_table.viz.id
}

resource "aws_network_acl" "viz" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.viz.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
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