# Note: don't use use1-az3 availability zone, not allowed for EKS according to the docs
# both in staging and prod 'a' and 'b' are safe.

data "aws_nat_gateway" "nat_gateway" {
  id = var.nat_gateway_id
}

resource "aws_subnet" "jupyterhub_eks_public_a" {
  vpc_id            = var.vpc_id
  cidr_block        = var.jupyterhub_eks_public_a_cidr
  availability_zone = "${var.aws_region}a"

  map_public_ip_on_launch = true

  tags = {
    Name           = "jupyterhub-eks-public-a"
    SBO_Billing    = "jupyterhub"
    JupyterHubType = "public"
  }
}

resource "aws_subnet" "jupyterhub_eks_public_b" {
  vpc_id            = var.vpc_id
  cidr_block        = var.jupyterhub_eks_public_b_cidr
  availability_zone = "${var.aws_region}b"

  map_public_ip_on_launch = true

  tags = {
    Name           = "jupyterhub-eks-public-b"
    SBO_Billing    = "jupyterhub"
    JupyterHubType = "public"
  }
}

resource "aws_subnet" "jupyterhub_eks_private_a" {
  vpc_id            = var.vpc_id
  cidr_block        = var.jupyterhub_eks_private_a_cidr
  availability_zone = "${var.aws_region}a"

  tags = {
    Name           = "jupyterhub-eks-private-a"
    SBO_Billing    = "jupyterhub"
    JupyterHubType = "private"
  }
}

resource "aws_subnet" "jupyterhub_eks_private_b" {
  vpc_id            = var.vpc_id
  cidr_block        = var.jupyterhub_eks_private_b_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name           = "jupyterhub-eks-private-b"
    SBO_Billing    = "jupyterhub"
    JupyterHubType = "private"
  }
}

# network ACL for public subnets

resource "aws_network_acl" "jupyterhub_eks_public" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "jupyterhub-eks-public-acl"
    SBO_Billing = "jupyterhub"
  }
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_endpoints_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 50
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_alb_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 55
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_alb_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 56
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_notebook_service_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 57
  protocol       = "tcp"
  from_port      = 2049
  to_port        = 2049
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_a
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_notebook_service_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 58
  protocol       = "tcp"
  from_port      = 2049
  to_port        = 2049
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_b
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_public_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 60
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_a_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_public_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 61
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_b_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_private_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 62
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_a_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_private_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 63
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_b_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_deny_rest_of_vpc_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_endpoints_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 50
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_alb_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 55
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_alb_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 56
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_notebook_service_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 57
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_notebook_service_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 58
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_b
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_public_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 60
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_a_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_public_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 61
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_b_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_private_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 62
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_a_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_private_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 63
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_b_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_deny_rest_of_vpc_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_public_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

# network ACL for private subnets

resource "aws_network_acl" "jupyterhub_eks_private" {
  vpc_id = var.vpc_id

  tags = {
    Name        = "jupyterhub-eks-private-acl"
    SBO_Billing = "jupyterhub"
  }
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_nat_gateway_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 50
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "${data.aws_nat_gateway.nat_gateway.private_ip}/32"
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_endpoints_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_alb_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 55
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_alb_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 56
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_notebook_service_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 57
  protocol       = "tcp"
  from_port      = 2049
  to_port        = 2049
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_a
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_notebook_service_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 58
  protocol       = "tcp"
  from_port      = 2049
  to_port        = 2049
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_b
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_public_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 60
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_a_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_public_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 61
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_b_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_private_a_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 62
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_a_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_private_b_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 63
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_b_cidr
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_deny_rest_of_vpc_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_allow_internet_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = false
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_nat_gateway_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 50
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "${data.aws_nat_gateway.nat_gateway.private_ip}/32"
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_endpoints_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.aws_endpoints_subnet_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_alb_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 55
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_alb_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 56
  protocol       = "tcp"
  from_port      = 443
  to_port        = 443
  rule_action    = "allow"
  cidr_block     = var.private_alb_cidr_b
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_notebook_service_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 57
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_a
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_notebook_service_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 58
  protocol       = "tcp"
  from_port      = 1024
  to_port        = 65535
  rule_action    = "allow"
  cidr_block     = var.notebook_service_cidr_b
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_public_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 60
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_a_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_public_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 61
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_public_b_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_private_a_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 62
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_a_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_private_b_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 63
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = var.jupyterhub_eks_private_b_cidr
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_deny_rest_of_vpc_egress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 100
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = var.vpc_cidr_block
  egress         = true
}

resource "aws_network_acl_rule" "jupyterhub_eks_private_deny_allow_internet_ingress" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  rule_number    = 101
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  egress         = true
}

# Associations

resource "aws_network_acl_association" "jupyterhub_eks_public_a" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  subnet_id      = aws_subnet.jupyterhub_eks_public_a.id
}

resource "aws_network_acl_association" "jupyterhub_eks_public_b" {
  network_acl_id = aws_network_acl.jupyterhub_eks_public.id
  subnet_id      = aws_subnet.jupyterhub_eks_public_b.id
}

resource "aws_network_acl_association" "jupyterhub_eks_private_a" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  subnet_id      = aws_subnet.jupyterhub_eks_private_a.id
}

resource "aws_network_acl_association" "jupyterhub_eks_private_b" {
  network_acl_id = aws_network_acl.jupyterhub_eks_private.id
  subnet_id      = aws_subnet.jupyterhub_eks_private_b.id
}

resource "aws_route_table_association" "jupyterhub_eks_private_a" {
  subnet_id      = aws_subnet.jupyterhub_eks_private_a.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_route_table_association" "jupyterhub_eks_private_b" {
  subnet_id      = aws_subnet.jupyterhub_eks_private_b.id
  route_table_id = var.route_table_private_subnets_id
}

resource "aws_route_table_association" "jupyterhub_eks_public_a" {
  subnet_id      = aws_subnet.jupyterhub_eks_public_a.id
  route_table_id = var.route_table_public_subnets_id
}

resource "aws_route_table_association" "jupyterhub_eks_public_b" {
  subnet_id      = aws_subnet.jupyterhub_eks_public_b.id
  route_table_id = var.route_table_public_subnets_id
}
