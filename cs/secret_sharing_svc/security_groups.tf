data "aws_vpc" "main" {
  id = var.vpc_id
}

resource "aws_security_group" "secret_sharing_svc_sg" {
  name        = "secret_sharing_svc"
  vpc_id      = var.vpc_id
  description = "SG for the secret_sharing service"

  tags = {
    SBO_Billing = "secret_sharing_svc"
    Name        = "secret_sharing_svc"
  }
}

resource "aws_vpc_security_group_ingress_rule" "secret_sharing_svc_allow_http_internal" {
  security_group_id = aws_security_group.secret_sharing_svc_sg.id
  description       = "Allow HTTP from internal"
  from_port         = var.secret_sharing_svc_port
  to_port           = var.secret_sharing_svc_port
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.main.cidr_block

  tags = {
    SBO_Billing = "secret_sharing_svc"
    Name        = "secret_sharing_svc_allow_http_internal"
  }
}

resource "aws_vpc_security_group_egress_rule" "secret_sharing_svc_allow_everything_outgoing" {
  security_group_id = aws_security_group.secret_sharing_svc_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "secret_sharing_svc"
    Name        = "secret_sharing_svc_allow_everything_outgoing"
  }
}
