resource "aws_acm_certificate" "cell_svc" {
  domain_name       = var.cell_svc_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = { SBO_Billing = "cell_svc" }
}

resource "aws_route53_record" "cell_svc_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cell_svc.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "cell_svc" {
  certificate_arn         = aws_acm_certificate.cell_svc.arn
  validation_record_fqdns = [for record in aws_route53_record.cell_svc_validation : record.fqdn]
}

resource "aws_lb_target_group" "cell_svc" {
  #ts:skip=AC_AWS_0492
  name_prefix = "cllb"
  port        = 8050
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "/health"
    protocol = "HTTP"
  }
  tags = { SBO_Billing = "cell_svc" }
}

resource "aws_lb_listener_certificate" "cell_svc" {
  listener_arn    = var.public_alb_https_listener_arn
  certificate_arn = aws_acm_certificate_validation.cell_svc.certificate_arn
}

resource "aws_lb_listener_rule" "cell_svc_https" {
  listener_arn = var.public_alb_https_listener_arn
  priority     = 700

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cell_svc.arn
  }

  condition {
    host_header {
      values = [var.cell_svc_hostname]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = { SBO_Billing = "cell_svc" }
}

resource "aws_route53_record" "cell_svc" {
  zone_id = var.domain_zone_id
  name    = var.cell_svc_hostname
  type    = "CNAME"
  ttl     = 60
  records = [var.public_alb_dns_name]
}
