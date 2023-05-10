resource "aws_acm_certificate" "core_webapp" {
  domain_name       = var.core_webapp_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_route53_record" "core_webapp_validation" {
  for_each = {
    for dvo in aws_acm_certificate.core_webapp.domain_validation_options : dvo.domain_name => {
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
  zone_id         = data.terraform_remote_state.common.outputs.domain_zone_id
}

resource "aws_acm_certificate_validation" "core_webapp" {
  certificate_arn         = aws_acm_certificate.core_webapp.arn
  validation_record_fqdns = [for record in aws_route53_record.core_webapp_validation : record.fqdn]
}

resource "aws_lb_target_group" "core_webapp" {
  #ts:skip=AC_AWS_0492
  name        = "core-webapp"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_certificate" "core_webapp" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.core_webapp.arn
}


resource "aws_lb_listener_rule" "core_webapp_https" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp.arn
  }

  condition {
    host_header {
      values = [var.core_webapp_hostname]
    }
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "core_webapp" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.core_webapp_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

output "alb_core_webapp_hostname" {
  value = var.core_webapp_hostname
}