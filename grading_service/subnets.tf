# Subnets for the grading service (API + Redis)
# Placeholder CIDRs — verify these are free before applying
resource "aws_subnet" "grading_service_a" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}a"
  cidr_block        = "10.0.38.0/27"
  tags = {
    Name = "grading_service_a"
  }
}

resource "aws_subnet" "grading_service_b" {
  vpc_id            = var.vpc_id
  availability_zone = "${var.aws_region}b"
  cidr_block        = "10.0.38.32/27"
  tags = {
    Name = "grading_service_b"
  }
}

# Route table associations — private route table with NAT gateway for internet access
resource "aws_route_table_association" "grading_service_a" {
  subnet_id      = aws_subnet.grading_service_a.id
  route_table_id = var.internet_access_route_id
}

resource "aws_route_table_association" "grading_service_b" {
  subnet_id      = aws_subnet.grading_service_b.id
  route_table_id = var.internet_access_route_id
}

# ---------------------------------------------------------------
# Network ACL — VPC isolation
#
# Strategy (follows cs/jupyterhub_eks/subnets.tf pattern):
#   Low rule numbers: allow own-subnet, ALB, and VPC endpoints traffic
#   Rule 90:          DENY entire VPC CIDR
#   Rule 100:         allow 0.0.0.0/0 (internet via NAT, source IPs are external)
# ---------------------------------------------------------------

resource "aws_network_acl" "grading_service" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "grading-service-acl"
    SBO_Billing = "grading_service"
  }
}

# --- Inbound rules ---

# Allow own-subnet traffic (Redis <-> API)
resource "aws_network_acl_rule" "ingress_own_subnet_a" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 10
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_subnet.grading_service_a.cidr_block
  egress         = false
}

resource "aws_network_acl_rule" "ingress_own_subnet_b" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 11
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_subnet.grading_service_b.cidr_block
  egress         = false
}

# Allow ALB health checks and forwarded traffic (ephemeral ports)
resource "aws_network_acl_rule" "ingress_alb_a" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 20
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = false
}

resource "aws_network_acl_rule" "ingress_alb_b" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 21
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = false
}

# Allow AWS VPC endpoints (ECR, CloudWatch, etc.)
resource "aws_network_acl_rule" "ingress_endpoints" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 30
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = false
}

# DENY all remaining VPC traffic
resource "aws_network_acl_rule" "ingress_deny_vpc" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 90
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = false
}

# Allow internet (return traffic from NAT — source IPs are external)
resource "aws_network_acl_rule" "ingress_internet" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = false
}

# --- Outbound rules ---

# Allow own-subnet traffic
resource "aws_network_acl_rule" "egress_own_subnet_a" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 10
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_subnet.grading_service_a.cidr_block
  egress         = true
}

resource "aws_network_acl_rule" "egress_own_subnet_b" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 11
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_subnet.grading_service_b.cidr_block
  egress         = true
}

# Allow response traffic to ALB (HTTPS + ephemeral ports)
resource "aws_network_acl_rule" "egress_alb_a_https" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 20
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "egress_alb_b_https" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 21
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = true
}

resource "aws_network_acl_rule" "egress_alb_a_ephemeral" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 22
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "egress_alb_b_ephemeral" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 23
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = true
}

# Allow AWS VPC endpoints
resource "aws_network_acl_rule" "egress_endpoints" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 30
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = true
}

# DENY all remaining VPC traffic
resource "aws_network_acl_rule" "egress_deny_vpc" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 90
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = true
}

# Allow internet outbound (via NAT gateway)
resource "aws_network_acl_rule" "egress_internet" {
  network_acl_id = aws_network_acl.grading_service.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

# --- NACL Associations ---

resource "aws_network_acl_association" "grading_service_a" {
  network_acl_id = aws_network_acl.grading_service.id
  subnet_id      = aws_subnet.grading_service_a.id
}

resource "aws_network_acl_association" "grading_service_b" {
  network_acl_id = aws_network_acl.grading_service.id
  subnet_id      = aws_subnet.grading_service_b.id
}
