resource "aws_lb_target_group" "accounting" {
  #ts:skip=AC_AWS_0492
  name        = "accounting"
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

  tags = {
    SBO_Billing = "accounting"
  }
}

resource "aws_lb_listener_rule" "accounting" {
  listener_arn = var.alb_listener_arn
  priority     = 650

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.accounting.arn
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }

  tags = {
    SBO_Billing = "accounting"
  }
}
