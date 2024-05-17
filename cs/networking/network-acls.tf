resource "aws_network_acl" "cs_subnet" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    # cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
    from_port = 0
    to_port   = 0
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
    Name        = "cs_subnet_acl"
    SBO_Billing = "cs_subnet"
  }
}
