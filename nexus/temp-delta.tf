resource "aws_acm_certificate" "nexus_app" {
  domain_name       = var.nexus_delta_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_route53_record" "nexus_app_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nexus_app.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.domain_zone_id
}

resource "aws_acm_certificate_validation" "nexus_app" {
  certificate_arn         = aws_acm_certificate.nexus_app.arn
  validation_record_fqdns = [for record in aws_route53_record.nexus_app_validation : record.fqdn]
}

resource "aws_lb_target_group" "nexus_app" {
  #ts:skip=AC_AWS_0492
  name_prefix          = "nx-dlt"
  port                 = 8080
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = "20"
  health_check {
    enabled             = true
    path                = "/v1/version"
    protocol            = "HTTP"
    unhealthy_threshold = 10
    timeout             = 10
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_lb_listener_certificate" "nexus_app" {
  listener_arn    = var.aws_lb_listener_sbo_https_arn
  certificate_arn = aws_acm_certificate_validation.nexus_app.certificate_arn
}

data "aws_nat_gateway" "provided_nat_gateway" {
  id = var.nat_gateway_id
}

resource "aws_lb_listener_rule" "nexus_app_https" {
  listener_arn = var.aws_lb_listener_sbo_https_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus_app.arn
  }

  condition {
    host_header {
      values = [var.nexus_delta_hostname]
    }
  }

  condition {
    source_ip {
      values = concat(var.allowed_source_ip_cidr_blocks, [format("%s/32", data.aws_nat_gateway.provided_nat_gateway.public_ip)])
    }
  }

  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_route53_record" "nexus_app" {
  zone_id = var.domain_zone_id
  name    = var.nexus_delta_hostname
  type    = "CNAME"
  ttl     = 60
  records = [var.aws_lb_alb_dns_name]
}

resource "aws_route53_record" "nexus_app_efs" {
  zone_id = var.domain_zone_id
  name    = "nexus-app-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.delta.efs_delta_dns_name]
}

output "alb_nexus_app_hostname" {
  value = var.nexus_delta_hostname
}