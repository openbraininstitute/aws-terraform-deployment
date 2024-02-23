resource "aws_acm_certificate" "kg_inference_api_certificate" {
  domain_name       = var.kg_inference_api_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}


resource "aws_route53_record" "kg_inference_api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.kg_inference_api_certificate.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "kg_inference_api" {
  certificate_arn         = aws_acm_certificate.kg_inference_api_certificate.arn
  validation_record_fqdns = [for record in aws_route53_record.kg_inference_api_validation : record.fqdn]
}

# Target Group definition
resource "aws_lb_target_group" "kg_inference_api_tg" {
  name        = "kg-inference-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "/docs"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_lb_listener_certificate" "kg_inference_api" {
  listener_arn    = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  certificate_arn = aws_acm_certificate_validation.kg_inference_api.certificate_arn
}

resource "aws_lb_listener_rule" "kg_inference_api" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kg_inference_api_tg.arn
  }

  condition {
    host_header {
      values = [var.kg_inference_api_hostname]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_route53_record" "kg_inference_api" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.kg_inference_api_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.public_alb_dns_name]
}

output "alb_kg_inference_api_hostname" {
  value = var.kg_inference_api_hostname
}