resource "aws_security_group" "efa" {
  name   = "Security group for EFA"
  vpc_id = var.pcluster_vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "ring_of_trust_in" {
  security_group_id            = aws_security_group.efa.id
  referenced_security_group_id = aws_security_group.efa.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.efa.id
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "ring_of_trust_out" {
  security_group_id            = aws_security_group.efa.id
  referenced_security_group_id = aws_security_group.efa.id
  ip_protocol                  = "-1"
}
