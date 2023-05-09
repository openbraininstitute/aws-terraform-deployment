resource "aws_lb" "alb" {
  name               = "sbo-poc-alb"
  internal           = false #tfsec:ignore:aws-elb-alb-not-public
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]

  drop_invalid_header_fields = true

  tags = {
    Name        = "sbo-poc-alb",
    SBO_Billing = "common"
  }
}

# See https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-update-security-groups.html
resource "aws_security_group" "alb" {
  name        = "Load balancer"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  description = "Sec group for the application load balancer"

  tags = {
    Name        = "alb_secgroup"
    SBO_Billing = "common"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_epfl" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from EPFL"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = var.epfl_cidr

  tags = {
    Name = "alb_allow_https_epfl"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https_internal" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internal"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4         = data.terraform_remote_state.common.outputs.vpc_cidr_block

  tags = {
    Name = "alb_allow_https_internal"
  }
}

# TODO limit to only the listener ports and health check ports of the instance groups
resource "aws_vpc_security_group_egress_rule" "alb_allow_everything_outgoing" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow everything outgoing"
  ip_protocol       = -1
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "alb_allow_everything_outgoing"
  }
}

output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}
