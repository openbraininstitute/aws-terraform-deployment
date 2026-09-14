#  Configure ALB target group
resource "aws_lb_target_group" "private_keycloak_target_group" {
  name        = "private-keycloak-target-group"
  port        = var.keycloak_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "Private Keycloak Target Group"
    SBO_Billing = "keycloak"
  }
  health_check {
    path                = "/auth/health/ready"
    port                = var.keycloak_management_port
    protocol            = "HTTP"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

# OAuth/OIDC discovery well-known paths that Keycloak does NOT serve directly.
# MCP clients (Claude Desktop) probe several well-known forms in order and abort
# the whole flow if any probe returns a REDIRECT ("redirect policy was
# 'error'"). Keycloak only serves the path-appended form
# (/auth/realms/<realm>/.well-known/openid-configuration, HTTP 200); the other
# forms must therefore return a terminal 404 (NOT a redirect) so the client
# falls through to that working form. Returning 404 here (instead of the
# listener's default cross-host 302 to the frontend) is what unblocks the walk.
resource "aws_lb_listener_rule" "oauth_authorization_server_metadata_root_404" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 560
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"not_found\"}"
      status_code  = "404"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
  condition {
    path_pattern {
      values = ["/.well-known/oauth-authorization-server"]
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_rule" "openid_configuration_root_404" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 561
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"not_found\"}"
      status_code  = "404"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
  condition {
    path_pattern {
      values = ["/.well-known/openid-configuration"]
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_rule" "oauth_authorization_server_metadata_404" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 562
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"not_found\"}"
      status_code  = "404"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
  condition {
    path_pattern {
      values = ["/.well-known/oauth-authorization-server/auth/realms/${var.keycloak_realm}"]
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_rule" "openid_configuration_404" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 563
  action {
    type = "fixed-response"
    fixed_response {
      content_type = "application/json"
      message_body = "{\"error\":\"not_found\"}"
      status_code  = "404"
    }
  }
  condition {
    host_header {
      values = [var.domain_name]
    }
  }
  condition {
    path_pattern {
      values = ["/.well-known/openid-configuration/auth/realms/${var.keycloak_realm}"]
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_rule" "private_keycloak_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 565
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_keycloak_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
  condition {
    source_ip {
      values = var.keycloak_allowed_source_ip_cidr_blocks
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_certificate" "keycloak_admin" {
  listener_arn    = var.private_alb_https_listener_arn
  certificate_arn = var.keycloak_admin_cert_arn
}

resource "aws_lb_listener_rule" "private_keycloak_admin_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 564
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_keycloak_target_group.arn
  }

  condition {
    host_header {
      values = [var.keycloak_admin_hostname]
    }
  }
  condition {
    source_ip {
      values = var.keycloak_admin_allowed_source_ip_cidr_blocks
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}
