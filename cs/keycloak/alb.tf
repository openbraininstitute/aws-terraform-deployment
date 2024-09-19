#  Configure ALB target group
resource "aws_lb_target_group" "keycloak_target_group" {
  name        = "keycloak-target-group"
  port        = 8081
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "Keycloak Target Group"
    SBO_Billing = "keycloak"
  }
  health_check {
    path                = "/auth/health"
    port                = "8081"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

# redirect any request for /auth* using one of the var.redirect_hostnames
# to /auth on the preferred hostname.

# Generates a separate rule for each of the hostnames in redirect_hostnames
# => each individual rule remains below the 5 conditions limit
resource "aws_lb_listener_rule" "keycloak_redirect" {
  # Generates a set [0, 1, 2, ..] with an index for each entry in var.redirect_hostnames
  for_each = toset(formatlist("%s", range(length(var.redirect_hostnames))))

  listener_arn = var.public_alb_listener
  priority     = 555 + each.value

  action {
    type = "redirect"
    redirect {
      protocol    = "HTTP"
      host        = var.preferred_hostname
      path        = "/#{path}"
      status_code = "HTTP_302"
    }
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
  condition {
    host_header {
      values = [var.redirect_hostnames[each.value]]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "keycloak"
  }
}

resource "aws_lb_listener_rule" "keycloak_https" {
  listener_arn = var.public_alb_listener
  priority     = 565
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keycloak_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}
