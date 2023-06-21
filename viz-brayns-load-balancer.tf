resource "aws_acm_certificate" "brayns" {
  domain_name       = var.private_viz_brayns_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_route53_record" "brayns_validation" {
  for_each = {
    for dvo in aws_acm_certificate.brayns.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "brayns" {
  certificate_arn         = aws_acm_certificate.brayns.arn
  validation_record_fqdns = [for record in aws_route53_record.brayns_validation : record.fqdn]
}

resource "aws_lb_listener_certificate" "brayns" {
  listener_arn    = aws_lb_listener.sbo_brayns.arn
  certificate_arn = aws_acm_certificate.brayns.arn
}

resource "aws_route53_record" "brayns" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.private_viz_brayns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_lb_listener" "sbo_brayns" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8200"
  protocol          = "HTTPS"

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

resource "aws_lb_target_group" "viz_brayns" {
  #ts:skip=AC_AWS_0492
  name        = "viz-brayns"
  port        = 8200
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_brayns_8200" {
  listener_arn = aws_lb_listener.sbo_brayns.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_brayns.arn
  }

  condition {
    host_header {
      values = [var.private_viz_brayns_hostname]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
  depends_on = [
    aws_lb_listener.sbo_brayns,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "private_viz_brayns" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.private_viz_brayns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.private_alb_dns_name]
}
