resource "aws_security_group" "acc_sg" {
  vpc_id = var.vpc_id

  name        = "main_bluenaas_sg"
  description = "main secruity group for bluenaas resources"

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  security_group_id = aws_security_group.acc_sg.id
  description       = "Allow everything incoming from the VPC"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.acc_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1

  tags = {
    SBO_Billing = "bluenaas"
  }
}
