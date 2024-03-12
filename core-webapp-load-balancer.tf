# TODO: delete POC related entries after migration to the production domain.
resource "aws_acm_certificate" "core_webapp_poc" {
  domain_name       = var.core_webapp_poc_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_route53_record" "core_webapp_poc_validation" {
  for_each = {
    for dvo in aws_acm_certificate.core_webapp_poc.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "core_webapp_poc" {
  certificate_arn         = aws_acm_certificate.core_webapp_poc.arn
  validation_record_fqdns = [for record in aws_route53_record.core_webapp_poc_validation : record.fqdn]
}

resource "aws_lb_listener_certificate" "core_webapp_poc" {
  listener_arn    = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  certificate_arn = aws_acm_certificate_validation.core_webapp_poc.certificate_arn
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
  health_check {
    enabled  = true
    path     = "/mmb-beta"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_rule" "core_webapp" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp.arn
  }

  condition {
    host_header {
      values = [var.core_webapp_hostname]
    }
  }

  condition {
    path_pattern {
      values = ["${var.core_webapp_base_path}*"]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_rule" "core_webapp_redirect" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 201

  action {
    type = "redirect"
    redirect {
      path        = "/mmb-beta"
      status_code = "HTTP_302"
    }
  }

  condition {
    host_header {
      values = [var.core_webapp_hostname]
    }
  }

  condition {
    path_pattern {
      values = ["/", "/static/coming-soon/index.html"]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_rule" "core_webapp_poc" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 202

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp.arn
  }

  condition {
    host_header {
      values = [var.core_webapp_poc_hostname]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_route53_record" "core_webapp_poc" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.core_webapp_poc_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.public_alb_dns_name]
}

output "alb_core_webapp_hostname" {
  value = var.core_webapp_hostname
}