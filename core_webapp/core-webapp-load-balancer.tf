resource "aws_lb_target_group" "core_webapp" {
  #ts:skip=AC_AWS_0492
  name        = "core-webapp"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
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
  listener_arn = var.public_alb_https_listener_arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp.arn
  }

  condition {
    path_pattern {
      values = ["${var.core_webapp_base_path}*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}

# Generates a separate rule for each of the ranges in allowed_source_ip_cidr_blocks
# => each individual rule remains below the 5 conditions limit
resource "aws_lb_listener_rule" "core_webapp_redirect" {
  # Generates a set [0, 1, 2, ..] with an index for each entry in var.cert_arns
  for_each = toset(formatlist("%s", range(length(var.allowed_source_ip_cidr_blocks))))

  listener_arn = var.public_alb_https_listener_arn
  priority     = 250 + each.value

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
      values = [var.allowed_source_ip_cidr_blocks[each.value]]
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}
