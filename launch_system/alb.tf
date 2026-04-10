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

locals {
  launch_cidr_chunks = chunklist(var.allowed_source_ip_cidr_blocks, 4)
}

resource "aws_lb_listener_rule" "launch_private_listener_rule" {
  for_each     = { for i, chunk in local.launch_cidr_chunks : i => chunk }
  listener_arn = var.private_alb_listener_arn
  priority     = var.listener_rule_base_priority + each.key

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
      values = each.value
    }
  }
}
