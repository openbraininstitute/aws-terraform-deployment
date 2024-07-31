resource "aws_lb_target_group" "lb_target_group" {
  #ts:skip=AC_AWS_0492
  name_prefix          = var.target_group_prefix
  port                 = var.target_port
  protocol             = "HTTP"
  target_type          = "ip"
  vpc_id               = var.vpc_id
  deregistration_delay = "20"
  health_check {
    enabled             = true
    path                = var.health_check_path
    protocol            = "HTTP"
    matcher             = var.health_check_code
    unhealthy_threshold = 10
    timeout             = 10
  }
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_nat_gateway" "provided_nat_gateway" {
  id = var.nat_gateway_id
}

resource "aws_lb_listener_rule" "lb_target_https" {
  listener_arn = var.public_lb_listener_https_arn
  priority     = var.unique_listener_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }

  condition {
    path_pattern {
      values = ["${var.base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = concat(var.allowed_source_ip_cidr_blocks, [format("%s/32", data.aws_nat_gateway.provided_nat_gateway.public_ip)])
    }
  }
}

resource "aws_lb_listener_rule" "lb_target_https_redirect" {
  listener_arn = var.public_lb_listener_https_arn
  priority     = var.unique_listener_priority + 1

  action {
    type = "redirect"
    redirect {
      path        = "${var.base_path}/"
      status_code = "HTTP_302"
    }
  }
  condition {
    path_pattern {
      values = [var.base_path]
    }
  }
}

