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
  # Allow ssh port 22 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 22
    to_port    = 22
  }
  # Allow port 80 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  # Allow port 443 from anywhere
  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  # Deny port 5000 (Brayns) from all other IPs
  ingress {
    protocol   = "tcp"
    rule_no    = 140
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 5000
    to_port    = 5000
  }
  # Deny port 8000 (BCSB) from all other IPs
  ingress {
    protocol   = "tcp"
    rule_no    = 150
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 8000
    to_port    = 8000
  }
  # Deny port 4444 (VSM) from all other IPs
  ingress {
    protocol   = "tcp"
    rule_no    = 160
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 4444
    to_port    = 4444
  }
  # Deny port 8888 (VSM-Proxy) from all other IPs
  ingress {
    protocol   = "tcp"
    rule_no    = 170
    action     = "deny"
    cidr_block = "0.0.0.0/0"
    from_port  = 8888
    to_port    = 8888
  }
  # Allow ingress to all other ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 900
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
