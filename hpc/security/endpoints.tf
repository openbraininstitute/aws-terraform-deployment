resource "aws_security_group" "endpoints" {
  name        = "endpoints"
  vpc_id      = var.obp_vpc_id
  description = "Security group to allow access to Endpoints within VPC"
}

resource "aws_vpc_security_group_ingress_rule" "allow_peering_access_to_endpoints" {
  security_group_id = aws_security_group.endpoints.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "Allow peering traffic to endpoints"
  cidr_ipv4   = data.aws_vpc.peering_vpc.cidr_block
}

resource "aws_vpc_security_group_ingress_rule" "allow_obp_vpc_access_to_endpoints" {
  security_group_id = aws_security_group.endpoints.id

  ip_protocol = -1
  from_port   = -1
  to_port     = -1
  description = "Allow OBP VPC traffic to endpoints"
  cidr_ipv4   = data.aws_vpc.provided_vpc.cidr_block
}
