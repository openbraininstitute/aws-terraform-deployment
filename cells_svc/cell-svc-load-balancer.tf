resource "aws_lb_target_group" "private_cell_svc" {
  #ts:skip=AC_AWS_0492
  name_prefix = "cllb"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled             = true
    path                = "${var.root_path}/health"
    protocol            = "HTTP"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = var.tags
}

resource "aws_lb_listener_rule" "cell_svc_private_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 700

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_cell_svc.arn
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

  tags = var.tags
}
