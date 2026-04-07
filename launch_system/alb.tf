resource "aws_lb_target_group" "private" {
  #ts:skip=AC_AWS_0492
  name        = "launch-system" # only alphanumeric characters and hyphens
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
}

resource "aws_lb_listener_rule" "launch_private_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = 613

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private.arn
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
}

resource "aws_lb_listener_rule" "launch_private_listener_rule_2" {
  count        = length(var.allowed_source_ip_cidr_blocks_2) > 0 ? 1 : 0
  listener_arn = var.private_alb_listener_arn
  priority     = 614

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private.arn
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks_2
    }
  }
}

resource "aws_lb_listener_rule" "launch_private_listener_rule_3" {
  count        = length(var.allowed_source_ip_cidr_blocks_3) > 0 ? 1 : 0
  listener_arn = var.private_alb_listener_arn
  priority     = 615

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private.arn
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks_3
    }
  }
}
