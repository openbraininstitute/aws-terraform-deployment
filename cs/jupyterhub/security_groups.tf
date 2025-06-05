data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_subnet" "jupyterhub_subnet" {
  id = var.jupyterhub_private_subnet
}

resource "aws_security_group" "jupyterhub_efs_sg" {
  name        = var.jupyterhub_sg_efs_name
  description = "Security group for JupyterHub EFS"
  vpc_id      = var.vpc_id
  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = var.jupyterhub_sg_efs_name
  }
}

resource "aws_vpc_security_group_egress_rule" "jupyterhub_efs_sg_egress" {
  security_group_id = aws_security_group.jupyterhub_efs_sg.id
  description       = "Allow egress to any destination"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = var.jupyterhub_sg_efs_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "jupyterhub_efs_sg_ingress" {
  security_group_id = aws_security_group.jupyterhub_efs_sg.id
  description       = "Allow ingress to NFS port from VPC"
  cidr_ipv4         = data.aws_subnet.jupyterhub_subnet.cidr_block
  ip_protocol       = "tcp"
  from_port         = 2049
  to_port           = 2049

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = var.jupyterhub_sg_efs_name
  }
}

# Security group for the public networks
resource "aws_security_group" "jupyterhub_sg" {
  name        = var.jupyterhub_sg_name
  vpc_id      = var.vpc_id
  description = "SG for the jupyterhub service"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = var.jupyterhub_sg_name
  }
}

resource "aws_vpc_security_group_ingress_rule" "jupyterhub_allow_http_internal" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow HTTP from internal"
  from_port         = var.jupyterhub_nginx_port
  to_port           = var.jupyterhub_nginx_port
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.main.cidr_block

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_http_internal"
  }
}

resource "aws_vpc_security_group_ingress_rule" "jupyterhub_allow_ssh_external" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow SSH from internal VPC"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.main.cidr_block
  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_ssh_internal"
  }
}

resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_everything_outgoing" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_everything_outgoing"
  }
}
