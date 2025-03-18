resource "aws_lb_target_group" "core_webapp_private" {
  #ts:skip=AC_AWS_0492
  name        = "core-webapp-${var.key}-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled = true
    // TODO Replace with a health check endpoint for core web app once implemented
    path     = "/"
    protocol = "HTTP"
    # TODO: Remove 307 when the domain redirect is implemented on AWS ALB level
    matcher = "200,307"
  }
  tags = {
    SBO_Billing = "core_webapp"
  }
}

resource "aws_lb_listener_rule" "private_core_webapp" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.core_webapp_private.arn
  }

  dynamic "condition" {
    for_each = var.allowed_source_ip_cidr_blocks != null ? [1] : []
    content {
      source_ip {
        values = var.allowed_source_ip_cidr_blocks
      }
    }
  }

  dynamic "condition" {
    for_each = var.hostname != null ? [1] : []
    content {
      host_header {
        values = [var.hostname]
      }
    }
  }

  tags = {
    SBO_Billing = "core_webapp"
  }
}
