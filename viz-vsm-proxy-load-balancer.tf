resource "aws_acm_certificate" "vsm_proxy" {
  domain_name       = var.viz_vsm_proxy_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_route53_record" "vsm_proxy_validation" {
  for_each = {
    for dvo in aws_acm_certificate.vsm_proxy.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "vsm_proxy" {
  certificate_arn         = aws_acm_certificate.vsm_proxy.arn
  validation_record_fqdns = [for record in aws_route53_record.vsm_proxy_validation : record.fqdn]
}

resource "aws_lb_listener_certificate" "vsm_proxy" {
  listener_arn    = aws_lb_listener.sbo_vsm_proxy.arn
  certificate_arn = aws_acm_certificate.vsm_proxy.arn
}

resource "aws_route53_record" "vsm_proxy" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.viz_vsm_proxy_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_lb_listener" "sbo_vsm_proxy" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 8888
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate.vsm_proxy.arn

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content: working"
      status_code  = "200"
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
  depends_on = [
    aws_lb.alb
  ]
}

resource "aws_lb_target_group" "viz_vsm_proxy" {
  #ts:skip=AC_AWS_0492
  name_prefix = "vsmp"
  port        = 8888
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  health_check {
    path = "/healthz"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_vsm_proxy_8888" {
  listener_arn = aws_lb_listener.sbo_vsm_proxy.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_vsm_proxy.arn
  }

  condition {
    host_header {
      values = [var.viz_vsm_proxy_hostname]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
  depends_on = [
    aws_lb_listener.sbo_vsm_proxy,
    aws_lb.alb
  ]
}