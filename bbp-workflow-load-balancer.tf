# https://bbp-workflow.shapes-registry.org/          => via LB => HTTP to container:8082
# https://bbp-workflow-api.shapes-registry.org/      => via LB => HTTP to container:8100
# https://bbp-workflow-api-auth.shapes-registry.org/ => via LB => HTTP to container:8100
# https://bbp-workflow-web.shapes-registry.org/      => via LB => HTTP to container:8080


resource "aws_acm_certificate" "bbp_workflow" {
  domain_name       = var.bbp_workflow_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_acm_certificate" "bbp_workflow_api" {
  domain_name       = var.bbp_workflow_api_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "workflow"
  }
}


resource "aws_acm_certificate" "bbp_workflow_api_auth" {
  domain_name       = var.bbp_workflow_api_auth_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_acm_certificate" "bbp_workflow_web" {
  domain_name       = var.bbp_workflow_web_hostname
  validation_method = "DNS"
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_route53_record" "bbp_workflow_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bbp_workflow.domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "bbp_workflow_api_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bbp_workflow_api.domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "bbp_workflow_api_auth_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bbp_workflow_api_auth.domain_validation_options : dvo.domain_name => {
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

resource "aws_route53_record" "bbp_workflow_web_validation" {
  for_each = {
    for dvo in aws_acm_certificate.bbp_workflow_web.domain_validation_options : dvo.domain_name => {
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

resource "aws_acm_certificate_validation" "bbp_workflow" {
  certificate_arn         = aws_acm_certificate.bbp_workflow.arn
  validation_record_fqdns = [for record in aws_route53_record.bbp_workflow_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "bbp_workflow_api" {
  certificate_arn         = aws_acm_certificate.bbp_workflow_api.arn
  validation_record_fqdns = [for record in aws_route53_record.bbp_workflow_api_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "bbp_workflow_api_auth" {
  certificate_arn         = aws_acm_certificate.bbp_workflow_api_auth.arn
  validation_record_fqdns = [for record in aws_route53_record.bbp_workflow_api_auth_validation : record.fqdn]
}

resource "aws_acm_certificate_validation" "bbp_workflow_web" {
  certificate_arn         = aws_acm_certificate.bbp_workflow_web.arn
  validation_record_fqdns = [for record in aws_route53_record.bbp_workflow_web_validation : record.fqdn]
}

resource "aws_lb_target_group" "bbp_workflow" {
  #ts:skip=AC_AWS_0492
  name        = "bbp-workflow"
  port        = 8082
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  health_check {
    enabled  = true # TODO check with Genrich for the health check
    path     = "/healthz"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_lb_target_group" "bbp_workflow_api" {
  #ts:skip=AC_AWS_0492
  name        = "bbp-workflow-api"
  port        = 8100
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  health_check {
    enabled  = true # TODO check with Genrich for the health check
    path     = "/healthz"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "workflow"
  }
}


resource "aws_lb_target_group" "bbp_workflow_api_auth" {
  #ts:skip=AC_AWS_0492
  name        = "bbp-workflow-api-auth"
  port        = 8100
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  health_check {
    enabled  = true # TODO check with Genrich for the health check
    path     = "/healthz"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_lb_target_group" "bbp_workflow_web" {
  #ts:skip=AC_AWS_0492
  name        = "bbp-workflow-web"
  port        = 8080
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  health_check {
    enabled  = true # TODO check with Genrich for the health check
    path     = "/healthz"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "workflow"
  }
}

resource "aws_lb_listener_certificate" "bbp_workflow" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.bbp_workflow.arn
}

resource "aws_lb_listener_certificate" "bbp_workflow_api" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.bbp_workflow_api.arn
}

resource "aws_lb_listener_certificate" "bbp_workflow_api_auth" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.bbp_workflow_api_auth.arn
}

resource "aws_lb_listener_certificate" "bbp_workflow_web" {
  listener_arn    = aws_lb_listener.sbo_https.arn
  certificate_arn = aws_acm_certificate.bbp_workflow_web.arn
}

resource "aws_lb_listener_rule" "bbp_workflow" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 300

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bbp_workflow.arn
  }

  condition {
    host_header {
      values = [var.bbp_workflow_hostname]
    }
  }
  tags = {
    SBO_Billing = "workflow"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_lb_listener_rule" "bbp_workflow_api" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 301

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bbp_workflow_api.arn
  }

  condition {
    host_header {
      values = [var.bbp_workflow_api_hostname]
    }
  }
  tags = {
    SBO_Billing = "workflow"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_lb_listener_rule" "bbp_workflow_api_auth" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 302

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bbp_workflow_api_auth.arn
  }

  condition {
    host_header {
      values = [var.bbp_workflow_api_auth_hostname]
    }
  }
  tags = {
    SBO_Billing = "workflow"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_lb_listener_rule" "bbp_workflow_web" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 303

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bbp_workflow_web.arn
  }

  condition {
    host_header {
      values = [var.bbp_workflow_web_hostname]
    }
  }
  tags = {
    SBO_Billing = "workflow"
  }
  depends_on = [
    aws_lb_listener.sbo_https,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "bbp_workflow" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.bbp_workflow_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_route53_record" "bbp_workflow_api" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.bbp_workflow_api_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_route53_record" "bbp_workflow_api_auth" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.bbp_workflow_api_auth_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

resource "aws_route53_record" "bbp_workflow_web" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.bbp_workflow_web_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_lb.alb.dns_name]
}

output "alb_bbp_workflow_hostname" {
  value = var.bbp_workflow_hostname
}
output "alb_bbp_workflow_api_hostname" {
  value = var.bbp_workflow_api_hostname
}
output "alb_bbp_workflow_api_auth_hostname" {
  value = var.bbp_workflow_api_auth_hostname
}
output "alb_bbp_workflow_web_hostname" {
  value = var.bbp_workflow_web_hostname
}
