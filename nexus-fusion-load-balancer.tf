resource "aws_acm_certificate" "nexus_fusion" {
  domain_name       = var.nexus_delta_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_route53_record" "nexus_fusion_validation" {
  for_each = {
    for dvo in aws_acm_certificate.nexus_fusion.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "nexus_fusion" {
  certificate_arn         = aws_acm_certificate.nexus_fusion.arn
  validation_record_fqdns = [for record in aws_route53_record.nexus_fusion_validation : record.fqdn]
}

resource "aws_lb_target_group" "nexus_fusion" {
  #ts:skip=AC_AWS_0492
  name_prefix = "nx-fsn"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  health_check {
    enabled             = true
    path                = "/nexus/web/status"
    protocol            = "HTTP"
    unhealthy_threshold = 10
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_fusion"
  }
}

resource "aws_lb_listener_certificate" "nexus_fusion" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.nexus_fusion.arn
}


resource "aws_lb_listener_rule" "nexus_fusion_https" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 101

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nexus_fusion.arn
  }

  condition {
    host_header {
      values = [var.nexus_delta_hostname]
    }
  }
  tags = {
    SBO_Billing = "nexus_fusion"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "nexus_fusion" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.nexus_fusion_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

output "alb_nexus_fusion_hostname" {
  value = var.nexus_fusion_hostname
}