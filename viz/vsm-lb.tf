resource "aws_lb_target_group" "viz_vsm" {
  #ts:skip=AC_AWS_0492
  name_prefix = "vsm"
  port        = 4444
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.selected.id

  health_check {
    path = "/healthz"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_vsm" {
  listener_arn = var.alb_listener_arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_vsm.arn
  }

  condition {
    path_pattern {
      values = ["${var.vsm_base_path}*"]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_target_group" "private_viz_vsm" {
  #ts:skip=AC_AWS_0492
  name_prefix = "vsm"
  port        = 4444
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.aws_vpc.selected.id

  health_check {
    path = "/healthz"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "private_viz_vsm" {
  listener_arn = var.private_alb_listener_arn
  priority     = 150

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_viz_vsm.arn
  }

  condition {
    path_pattern {
      values = ["${var.vsm_base_path}*"]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
}
