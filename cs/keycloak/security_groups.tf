data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "efs_sg" {
  name        = "efs-sg"
  description = "Security group for EFS"
  vpc_id      = var.vpc_id
  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_efs_sg"
  }
}

resource "aws_vpc_security_group_egress_rule" "efs_sg_egress" {
  security_group_id = aws_security_group.efs_sg.id
  description       = "Allow egress to any destination"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_efs_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "efs_sg_ingress" {
  security_group_id = aws_security_group.efs_sg.id
  description       = "Allow ingress to NFS port from VPC"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049

  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_efs_sg"
  }
}

resource "aws_security_group" "main_sg" {
  vpc_id      = var.vpc_id
  name        = "keycloak_db_sg"
  description = "main secruity group for keycloak db"

  tags = {
    SBO_Billing = "keycloak"
    Name        = "keycloak_db_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "keycloak"
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
    SBO_Billing = "keycloak"
  }
}
