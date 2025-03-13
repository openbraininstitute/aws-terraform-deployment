resource "aws_lb_listener_rule" "redirect" {
  listener_arn = var.alb_https_listener_arn
  priority     = tostring(var.priority)

  action {
    type = "redirect"
    redirect {
      status_code = "HTTP_301"
      protocol    = "HTTPS"
      port        = "443"
      path        = var.to_path
      query       = var.to_query
      host        = var.primary_domain
    }
  }

  condition {
    path_pattern {
      values = [var.from_path]
    }
  }
}
