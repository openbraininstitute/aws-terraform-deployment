resource "aws_lb_target_group" "core_webapp_private" {
  #ts:skip=AC_AWS_0492
  name        = "core-webapp-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  health_check {
    enabled = true
    // TODO Replace with a health check endpoint for core web app once implemented
    path     = "/"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_rule" "private_core_webapp" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 1000

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp_private.arn
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
