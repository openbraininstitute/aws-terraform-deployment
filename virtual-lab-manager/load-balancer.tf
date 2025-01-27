
resource "aws_lb_target_group" "virtual_lab_manager_private" {
  #ts:skip=AC_AWS_0492
  name        = "virtual-lab-manager-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.virtual_lab_manager_base_path}/health"
    protocol = "HTTP"
  }

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}

resource "aws_lb_listener_rule" "virtual_lab_manager_private" {
  listener_arn = var.private_lb_listener_https_arn
  priority     = 203

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.virtual_lab_manager_private.arn
  }

  condition {
    path_pattern {
      values = ["${var.virtual_lab_manager_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = ["0.0.0.0/0"]
    }
  }

  tags = {
    SBO_Billing = "virtual_lab_manager"
  }
}
