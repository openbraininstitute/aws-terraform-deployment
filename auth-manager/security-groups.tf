resource "aws_security_group" "auth_manager_sg" {
  vpc_id = var.vpc_id

  name        = "main_auth_manager_sg"
  description = "main security group for auth manager database"

  ingress {
    description = "Allow Postgres access from the VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = var.allowed_source_ip_cidr_blocks
  }

  tags = var.auth_manager_svc_tags
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.acc_sg.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.acc_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
}
