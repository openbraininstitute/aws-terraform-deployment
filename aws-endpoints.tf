# Goal: create an endpoint for the secretsmanager within the VPC, so that
# ECS can access the secret to download the dockerhub credentials to access
# our private repositories from within the VPC.
# https://aws.amazon.com/blogs/security/how-to-connect-to-aws-secrets-manager-service-within-a-virtual-private-cloud/

# TODO Not yet working. Likely somehow ECS containers have to be switched from public DNS to private DNS.
# See also https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
# DNS server should be at 10.0.0.2 . Also to check: enable_dns_hostnames option in aws_pvc.

# 10.0.2.16/28 is 10.0.2.16 up to 10.0.2.31 with subnet and broadcast included
resource "aws_subnet" "aws_endpoints" {
  vpc_id                  = data.terraform_remote_state.common.outputs.vpc_id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.16/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "aws_endpoints"
    SBO_Billing = "common"
  }
}

# Route table for the aws_endpoints network
# TODO routing via NAT probably not needed
resource "aws_route_table" "aws_endpoints" {
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = data.terraform_remote_state.common.outputs.nat_gateway_id
  }
  tags = {
    Name        = "aws_endpoints_route"
    SBO_Billing = "common"
  }
}

# Link route table to aws_endpoints network
resource "aws_route_table_association" "aws_endpoints" {
  subnet_id      = aws_subnet.aws_endpoints.id
  route_table_id = aws_route_table.aws_endpoints.id
}

resource "aws_network_acl" "aws_endpoints" {
  vpc_id     = data.terraform_remote_state.common.outputs.vpc_id
  subnet_ids = [aws_subnet.aws_endpoints.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = data.terraform_remote_state.common.outputs.vpc_cidr_block
    from_port  = 0
    to_port    = 0
  }
  /* # Allow temporarily all
  ingress {
    protocol = -1
    rule_no = 101
    action = "allow"
    cidr_block = "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }*/
  # allow ingress ephemeral ports
  ingress {
    protocol   = "tcp"
    rule_no    = 300
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  egress {
    # TODO probably egress not needed at all?
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "aws_endpoints_acl"
    SBO_Billing = "common"
  }
}

resource "aws_security_group" "aws_endpoint_secretsmanager" {
  name        = "AWS secretsmanager endpoint"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for the endpoint of the AWS secretsmanager"

  tags = {
    Name        = "aws_endpoint_secretsmanager_secgroup"
    SBO_Billing = "common"
  }
}

# TODO could be limited to just certain private subnets?
resource "aws_vpc_security_group_ingress_rule" "aws_endpoint_secretsmanager_incoming" {
  security_group_id = aws_security_group.aws_endpoint_secretsmanager.id
  description       = "Allow all incoming from VPC"
  from_port         = 0
  to_port           = 0
  ip_protocol       = "tcp"
  cidr_ipv4         = data.terraform_remote_state.common.outputs.vpc_cidr_block

  tags = {
    Name = "aws_endpoint_secretsmanager_incoming"
  }
}

# TODO limit to certain services
# probably egress not needed at all?
resource "aws_vpc_security_group_egress_rule" "aws_endpoint_secretsmanager_outgoing" {
  security_group_id = aws_security_group.aws_endpoint_secretsmanager.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "aws_endpoint_secretsmanager_outgoing"
  }
}

resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id             = data.terraform_remote_state.common.outputs.vpc_id
  service_name       = "com.amazonaws.${var.aws_region}.secretsmanager"
  auto_accept        = true
  ip_address_type    = "ipv4"
  subnet_ids         = [aws_subnet.aws_endpoints.id]
  security_group_ids = [aws_security_group.aws_endpoint_secretsmanager.id]
  tags = {
    Name        = "secretsmanager"
    SBO_Billing = "common"
  }
  vpc_endpoint_type = "Interface"
}

