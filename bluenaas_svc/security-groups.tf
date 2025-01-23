resource "aws_security_group" "main_sg" {
  vpc_id = var.vpc_id

  name        = "bluenaas_sg"
  description = "Main secruity group for bluenaas resources"
}

resource "aws_vpc_security_group_ingress_rule" "main_subnet_ingress" {
  # When tightening security don't forget to allow incoming TCP 2049 for EFS/NFS
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything incoming"
  ip_protocol       = -1
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  from_port         = -1
  to_port           = -1
}

resource "aws_vpc_security_group_egress_rule" "main_subnet_egress" {
  security_group_id = aws_security_group.main_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = -1
  to_port           = -1
}
