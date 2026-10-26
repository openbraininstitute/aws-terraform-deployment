resource "aws_lb_target_group" "entitycore_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "entitycore-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  # health checks are sent directly to the target, without the listener rule rewrite
  health_check {
    enabled             = true
    path                = "/health"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    interval            = 30
    timeout             = 10
  }
}

resource "aws_lb_listener_rule" "entitycore_private_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = 610

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.entitycore_private_tg.arn
  }

  # strip the root path, as expected by uvicorn --root-path:
  # /api/entitycore/foo -> /foo, /api/entitycore -> /
  transform {
    type = "url-rewrite"
    url_rewrite_config {
      rewrite {
        regex   = "^${var.root_path}/?(.*)$"
        replace = "/$1"
      }
    }
  }

  condition {
    path_pattern {
      values = [var.root_path, "${var.root_path}/*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }
}
