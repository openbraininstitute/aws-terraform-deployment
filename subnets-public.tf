# AWS load balancers require an IP address on at least
# 2 subnets in different availability zones.

# Public subnet in availability zone A
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.sbo_poc.id
  cidr_block              = "10.0.1.0/25"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true #tfsec:ignore:aws-ec2-no-public-ip-subnet
  tags = {
    Name        = "public_a"
    SBO_Billing = "common"
  }
}

# Public subnet in availability zone B
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.sbo_poc.id
  cidr_block              = "10.0.1.128/25"
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true #tfsec:ignore:aws-ec2-no-public-ip-subnet
  tags = {
    Name        = "public_b"
    SBO_Billing = "common"
  }
}

# Route table for the public network
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.sbo_poc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.igw.id
  }
  depends_on = [
    aws_internet_gateway.igw
  ]
  tags = {
    Name        = "public_route"
    SBO_Billing = "common"
  }
}

# Link route table to public network A
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

# Link route table to public network B
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# Security group for the public networks
resource "aws_security_group" "public" {
  name        = "public ACL"
  vpc_id      = aws_vpc.sbo_poc.id
  description = "Sec group for the public subnets"

  tags = {
    Name        = "public_acl"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_http_epfl" {
  security_group_id = aws_security_group.public.id
  description       = "Allow HTTP from EPFL"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name        = "public_allow_http_epfl"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_http_internal" {
  security_group_id = aws_security_group.public.id
  description       = "Allow HTTP from internal"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.sbo_poc.cidr_block

  tags = {
    Name        = "public_allow_http_internal"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_https_epfl" {
  security_group_id = aws_security_group.public.id
  description       = "Allow HTTPS from EPFL"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name        = "public_allow_https_epfl"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_https_internal" {
  security_group_id = aws_security_group.public.id
  description       = "Allow HTTPS from internal"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.sbo_poc.cidr_block

  tags = {
    Name        = "public_allow_https_internal"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh_epfl" {
  security_group_id = aws_security_group.public.id
  description       = "Allow SSH from EPFL"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name        = "public_allow_ssh_epfl"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "public_allow_ssh_internal" {
  security_group_id = aws_security_group.public.id
  description       = "Allow SSH from internal"
  from_port         = 22
  to_port           = 22
  ip_protocol       = "tcp"
  cidr_ipv4         = aws_vpc.sbo_poc.cidr_block

  tags = {
    Name        = "public_allow_ssh_internal"
    SBO_Billing = "common"
  }
}

/* Was used during debugging network issues
resource "aws_vpc_security_group_ingress_rule" "public_allow_everything" {
  security_group_id = aws_security_group.public.id
  description       = "Allow everything - not recommended"
  from_port         = 0
  to_port           = 0
  ip_protocol          = -1
  cidr_ipv4         = ["0.0.0.0/0"]

  tags = {
    Name        = "public_allow_ssh_internal"
    SBO_Billing = "common"
  }
}
*/

resource "aws_vpc_security_group_egress_rule" "public_allow_everything_outgoing" {
  security_group_id = aws_security_group.public.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name        = "public_allow_everything_outgoing"
    SBO_Billing = "common"
  }
}

# TODO: remove, separate ACL needed per VM/container/...
# TODO port 2049 for EFS traffic
resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.sbo_poc.id
  subnet_ids = [aws_subnet.public_a.id, aws_subnet.public_b.id]
  # Allow local traffic
  ingress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = aws_vpc.sbo_poc.cidr_block
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
  # Allow HTTPS from EPFL VPN range
  ingress {
    protocol   = "tcp"
    rule_no    = 105
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 443
    to_port    = 443
  }
  # Allow HTTP from EPFL VPN range
  ingress {
    protocol   = "tcp"
    rule_no    = 106
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 80
    to_port    = 80
  }
  # Allow SSH from EPFL VPN range
  ingress {
    protocol   = "tcp"
    rule_no    = 107
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 22
    to_port    = 22
  }
  # Allow port 8080 from EPFL VPN range
  ingress {
    protocol   = "tcp"
    rule_no    = 108
    action     = "allow"
    cidr_block = var.epfl_cidr
    from_port  = 8080
    to_port    = 8080
  }
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
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  tags = {
    Name        = "public_acl"
    SBO_Billing = "common"
  }
}
