data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_network_acl" "cs_subnet" {
  vpc_id     = var.vpc_id
  subnet_ids = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id, aws_subnet.cs_secret_sharing_svc_subnet.id, aws_subnet.cs_jupyterhub_subnet.id]

  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.aws_vpc.main.cidr_block
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 200
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
    SBO_Billing = "common"
  }
}
