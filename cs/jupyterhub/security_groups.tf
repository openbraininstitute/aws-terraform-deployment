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

resource "aws_vpc_security_group_ingress_rule" "jupyterhub_efs_sg_ingress" {
  security_group_id            = aws_security_group.jupyterhub_efs_sg.id
  description                  = "Allow NFS only from JupyterHub EC2 SG"
  referenced_security_group_id = aws_security_group.jupyterhub_sg.id
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = var.jupyterhub_sg_efs_name
  }

  lifecycle {
    create_before_destroy = true
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

# NFS to EFS mount target - scoped to EFS SG, not open internet
resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_nfs_to_efs" {
  security_group_id            = aws_security_group.jupyterhub_sg.id
  description                  = "Allow NFS to EFS mount target"
  ip_protocol                  = "tcp"
  from_port                    = 2049
  to_port                      = 2049
  referenced_security_group_id = aws_security_group.jupyterhub_efs_sg.id

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_nfs_to_efs"
  }
}

# HTTPS: needed for Keycloak OAuth, AWS APIs (Secrets Manager, SSM, CloudWatch), package installs during bootstrap.
# Runtime egress for notebook users (uid >= 1000) is blocked by iptables rules applied at the end of user_data,
# so this SG rule only benefits root/system processes after bootstrap completes.
resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_https_outgoing" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow HTTPS outgoing"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_https_outgoing"
  }
}

# HTTP: needed for apt and TLJH bootstrap installer.
# See HTTPS comment above re: runtime restriction via iptables.
resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_http_outgoing" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow HTTP outgoing (apt, TLJH bootstrap)"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_http_outgoing"
  }
}

# DNS
resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_dns_outgoing" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow DNS outgoing"
  ip_protocol       = "udp"
  from_port         = 53
  to_port           = 53
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_dns_outgoing"
  }
}

# NTP
resource "aws_vpc_security_group_egress_rule" "jupyterhub_allow_ntp_outgoing" {
  security_group_id = aws_security_group.jupyterhub_sg.id
  description       = "Allow NTP outgoing"
  ip_protocol       = "udp"
  from_port         = 123
  to_port           = 123
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    SBO_Billing = "jupyterhub_svc"
    Name        = "jupyterhub_allow_ntp_outgoing"
  }
}
