
# Target Group definition
resource "aws_lb_target_group" "thumbnail_generation_api_tg" {
  name        = "thumbnail-generation-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "${var.thumbnail_generation_api_base_path}/docs"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}

resource "aws_lb_listener_rule" "thumbnail_generation_api" {
  listener_arn = data.terraform_remote_state.common.outputs.public_alb_https_listener_arn
  priority     = 400

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.thumbnail_generation_api_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.thumbnail_generation_api_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = [var.epfl_cidr]
    }
  }

  tags = {
    SBO_Billing = "thumbnail_generation_api"
  }
}
