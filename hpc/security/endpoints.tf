resource "aws_security_group" "endpoints" {
  name        = "endpoints"
  vpc_id      = var.obp_vpc_id
  description = "Security group to allow access to Endpoints within VPC"
}

resource "aws_vpc_security_group_ingress_rule" "allow_access_to_endpoints" {
  security_group_id = aws_security_group.endpoints.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "Allow all traffic to endpoints"
  cidr_ipv4   = data.aws_vpc.peering_vpc.cidr_block
}
