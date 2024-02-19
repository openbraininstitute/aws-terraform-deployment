resource "aws_acm_certificate" "sbo_https_test" {
  domain_name       = var.sbo_https_test_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "common"
  }
}

resource "aws_route53_record" "sbo_https_test_validation" {
  for_each = {
    for dvo in aws_acm_certificate.sbo_https_test.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "sbo_https_test" {
  certificate_arn         = aws_acm_certificate.sbo_https_test.arn
  validation_record_fqdns = [for record in aws_route53_record.sbo_https_test_validation : record.fqdn]
}


resource "aws_route53_record" "sbo_https_test" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.sbo_https_test_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_lb_listener" "sbo_https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = aws_acm_certificate_validation.sbo_https_test.certificate_arn

  default_action {
    type = "redirect"

    redirect {
      path        = "/static/coming-soon/index.html"
      status_code = "HTTP_302"
    }
  }

  tags = {
    SBO_Billing = "common"
  }

  depends_on = [
    aws_lb.alb
  ]
}

output "alb_https_test" {
  value = var.sbo_https_test_hostname
}