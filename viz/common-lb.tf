resource "aws_lb" "alb" {
  count                      = local.sandbox_resource_count
  name                       = "franco-polonais-gateway"
  internal                   = false #tfsec:ignore:aws-elb-alb-not-public
  load_balancer_type         = "application"
  security_groups            = [data.aws_security_group.alb_selected.id]
  subnets                    = [aws_subnet.viz_public_b[0].id, aws_subnet.viz_public_a[0].id]
  drop_invalid_header_fields = true

  tags = {
    Name        = "sbo-poc-alb",
    SBO_Billing = "common"
  }
}


data "aws_security_group" "alb_selected" {
  id = var.viz_enable_sandbox ? aws_security_group.alb[0].id : var.aws_security_group_nlb_id
}


# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html
resource "aws_security_group" "alb" {
  count       = local.sandbox_resource_count
  name        = "Load balancer"
  vpc_id      = data.aws_vpc.selected.id
  description = "Sec group for the application load balancer"

  tags = {
    Name        = "alb_secgroup"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_brayns_epfl" {
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow Brayns on 5000 from EPFL"
  from_port         = 5000
  to_port           = 5000
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "alb_allow_brayns_epfl"
  }
}


resource "aws_vpc_security_group_ingress_rule" "alb_allow_vsm_epfl" {
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow VSM on 4444 from EPFL"
  from_port         = 4444
  to_port           = 4444
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "alb_allow_vsm_epfl"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_vsm_proxy_epfl" {
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow VSM-Proxy on 8888 from EPFL"
  from_port         = 8888
  to_port           = 8888
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "alb_allow_vsm_proxy_epfl"
  }
}

# Create those only in sandbox env
resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_internal" {
  count             = local.sandbox_resource_count
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow HTTPS from internal"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = data.aws_vpc.selected.cidr_block

  tags = {
    Name = "alb_allow_https_internal"
  }
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_everything_outgoing" {
  count             = local.sandbox_resource_count
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "alb_allow_everything_outgoing"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_epfl" {
  count             = local.sandbox_resource_count
  security_group_id = data.aws_security_group.alb_selected.id
  description       = "Allow HTTPS from EPFL"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "alb_allow_https_epfl"
  }
}
