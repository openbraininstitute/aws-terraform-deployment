resource "aws_security_group" "hpc_resource_provisioner" {
  name        = "HPC Resource Provisioner SG"
  description = "Security group to allow Resource Provisioner to access things"
  vpc_id      = var.obp_vpc_id
}

resource "aws_vpc_security_group_egress_rule" "resource_provisioner_https_to_vpc_endpoints" {
  security_group_id = aws_security_group.hpc_resource_provisioner.id
  cidr_ipv4         = var.aws_endpoints_subnet_cidr
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
}
