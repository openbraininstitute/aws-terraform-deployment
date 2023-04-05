# Subnet for the SBO core webapp
# 10.0.2.0/28 is 10.0.2.0 up to 10.0.2.15 with subnet and broadcast included
resource "aws_subnet" "core_webapp" {
  vpc_id                  = aws_vpc.sbo_poc.id
  availability_zone       = "${var.aws_region}a"
  cidr_block              = "10.0.2.0/28"
  map_public_ip_on_launch = false

  tags = {
    Name        = "core_webapp"
    SBO_Billing = "core_webapp"
  }
}

# Route table for the core_webapp network
resource "aws_route_table" "core_webapp" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }
  depends_on = [
    aws_nat_gateway.nat
  ]
  tags = {
    Name        = "core_webapp_route"
    SBO_Billing = "core_webapp"
  }
}
# Link route table to core_webapp network
resource "aws_route_table_association" "core_webapp" {
  subnet_id      = aws_subnet.core_webapp.id
  route_table_id = aws_route_table.core_webapp.id
}

resource "aws_security_group" "core_webapp" {
  name        = "Core WebAPP"
  vpc_id      = aws_vpc.sbo_poc.id
  description = "Sec group for the SBO core webapp"

  tags = {
    Name        = "core_webapp_secgroup"
    SBO_Billing = "core_webapp"
  }
}

# TODO: limit incoming ports to only 8000 and health check
# needs to be only accessible from ALB?
resource "aws_vpc_security_group_ingress_rule" "core_webapp_allow_http_8000" {
  security_group_id = aws_security_group.core_webapp.id
  description       = "Allow HTTP on port 8000"
  from_port         = 8000
  to_port           = 8000
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "core_webapp_allow_http_8000"
  }
}

# TODO limit to certain services
resource "aws_vpc_security_group_egress_rule" "core_webapp_allow_everything_outgoing" {
  security_group_id = aws_security_group.core_webapp.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "core_webapp_allow_everything_outgoing"
  }
}
