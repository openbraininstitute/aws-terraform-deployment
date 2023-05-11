# Subnet for compute nodes
resource "aws_subnet" "compute" {
  vpc_id            = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.32.0/21"
  tags = {
    Name        = "compute"
    SBO_Billing = "hpc"
  }
}

# Route table for the compute network
resource "aws_route_table" "compute" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "compute_route"
    SBO_Billing = "hpc"
  }
}

# Link route table to compute network
resource "aws_route_table_association" "compute" {
  subnet_id      = aws_subnet.compute.id
  route_table_id = aws_route_table.compute.id
}

resource "aws_network_acl" "compute" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.compute.id]
  # Allow local traffic
  # TODO limit to correct ports and subnets
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
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
    # TODO setup limits.
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "compute_acl"
    SBO_Billing = "hpc"
  }
}
