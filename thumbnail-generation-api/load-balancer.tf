
# Target Group definition
resource "aws_lb_target_group" "private_tg" {
  name        = "thumbnail-gen-api-tg-private"
  port        = 80
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
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_lb_listener_rule" "private" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}
