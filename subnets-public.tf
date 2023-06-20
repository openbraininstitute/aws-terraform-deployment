# AWS load balancers require an IP address on at least
# 2 subnets in different availability zones.

# Moved to the common repo, use:
# data.terraform_remote_state.common.outputs.public_a_subnet_id
# data.terraform_remote_state.common.outputs.public_a_subnet_arn
# data.terraform_remote_state.common.outputs.public_b_subnet_id
# data.terraform_remote_state.common.outputs.public_b_subnet_arn

resource "aws_network_acl" "public" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  # Allow port 80 from EPFL
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 80
    to_port    = 80
  }
  # Allow port 443 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 106
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # Allow port 22 from EPFL
  ingress {
    protocol   = "tcp"
    rule_no    = 107
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 22
    to_port    = 22
  }
  # Allow port 8200 (Brayns) from EPFL
  ingress {
    protocol   = "tcp"
    rule_no    = 108
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 8200
    to_port    = 8200
  }
  # Deny port 8200 (Brayns) from all other IPs
  ingress {
    protocol   = "tcp"
    rule_no    = 109
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 8200
    to_port    = 8200
  }
  # Allow ingress to all other ephemeral ports
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
    Name        = "public_subnet_acl"
    SBO_Billing = "common"
  }
}
