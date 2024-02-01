resource "aws_security_group" "main_sg" {
  vpc_id = var.vpc_id

  name        = "main_nexus_sg"
  description = "main secruity group for nexus resources"

  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.provided_vpc.cidr_block
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "nexus"
  }
}

# todo this is an old security group that is not used anymore and should be deleted.
# todo however if you remove it, it will fail because of a network interface
# todo that is still attached to it and that fails to delete. However the interface
# todo seems to also be unused. 🤔
resource "aws_security_group" "main_subnet_sg" {
  vpc_id = var.vpc_id

  name        = "nexus_es"
  description = "Nexus Elastic Search"

  tags = {
    SBO_Billing = "nexus"
  }
}
