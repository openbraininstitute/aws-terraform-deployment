resource "aws_lb_target_group" "bluenaas" {
  #ts:skip=AC_AWS_0492
  name        = "bluenaas"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.base_path}/health"
    protocol = "HTTP"
  }

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_lb_listener_rule" "bluenaas" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bluenaas.arn
  }

  condition {
    path_pattern {
      values = ["${var.base_path}*"]
    }
  }

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_lb_target_group" "bluenaas_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "bluenaas-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.base_path}/health"
    protocol = "HTTP"
  }

  tags = {
    SBO_Billing = "bluenaas"
  }
}

resource "aws_lb_listener_rule" "bluenaas_private_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bluenaas_private_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.base_path}*"]
    }
  }

  tags = {
    SBO_Billing = "bluenaas"
  }
}
