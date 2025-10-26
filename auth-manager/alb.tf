resource "aws_lb_target_group" "auth_manager_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "auth-manager-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.root_path}/health"
    protocol = "HTTP"
  }

  tags = var.auth_manager_svc_tags
}

resource "aws_lb_listener_rule" "auth_manager_private_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = 610

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.auth_manager_private_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }
  tags = var.auth_manager_svc_tags
}
