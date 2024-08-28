resource "aws_lb_target_group" "viz_vsm_proxy" {
  #ts:skip=AC_AWS_0492
  name_prefix = "vsmp"
  port        = 8888
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

resource "aws_lb_listener_rule" "viz_vsm_proxy_8888" {
  listener_arn = var.alb_listener_arn
  priority     = 151

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_vsm_proxy.arn
  }


  condition {
    path_pattern {
      values = ["${var.vsm_proxy_base_path}*"]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
}
