resource "aws_lb_target_group" "private_obi_one_v2" {
  #ts:skip=AC_AWS_0492
  name        = "obi-one-v2-private"
  port        = var.container_port
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

resource "aws_lb_listener_rule" "obi_one_v2_private_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 701

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_obi_one_v2.arn
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
