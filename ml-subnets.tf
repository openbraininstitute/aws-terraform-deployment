resource "aws_subnet" "ml_os" {
  vpc_id            = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.2.128/28"
  tags = {
    Name        = "ml_os"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_route_table" "ml_os" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "ml_os_route"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_route_table_association" "ml_os" {
  subnet_id      = aws_subnet.ml_os.id
  route_table_id = aws_route_table.ml_os.id
}

resource "aws_network_acl" "ml_os" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.ml_os.id]
  ingress {
    protocol   = -1
    rule_no    = 101
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
    # TODO probably not needed
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "ml_os_acl"
    SBO_Billing = "machinelearning"
  }
}
