resource "aws_acm_certificate" "nexus_delta" {
  domain_name       = var.nexus_delta_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_route53_record" "nexus_delta_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nexus_delta.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "nexus_delta" {
  certificate_arn         = aws_acm_certificate.nexus_delta.arn
  validation_record_fqdns = [for record in aws_route53_record.nexus_delta_validation : record.fqdn]
}

resource "aws_lb_target_group" "nexus_delta" {
  #ts:skip=AC_AWS_0492
  name_prefix = "nx-dlt"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  health_check {
    enabled             = true
    path                = "/v1/version"
    protocol            = "HTTP"
    unhealthy_threshold = 10
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_delta"
  }
}

resource "aws_lb_listener_certificate" "nexus_delta" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.nexus_delta.arn
}


resource "aws_lb_listener_rule" "nexus_delta_https" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus_delta.arn
  }

  condition {
    host_header {
      values = [var.nexus_delta_hostname]
    }
  }
  tags = {
    SBO_Billing = "nexus_delta"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "nexus_delta" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.nexus_delta_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

output "alb_nexus_delta_hostname" {
  value = var.nexus_delta_hostname
}