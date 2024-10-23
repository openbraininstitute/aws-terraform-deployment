
# Target Group definition
resource "aws_lb_target_group" "kg_inference_api_tg" {
  name        = "kg-inference-api-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "${var.kg_inference_api_base_path}/docs"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_lb_listener_rule" "kg_inference_api" {
  listener_arn = var.public_alb_https_listener_arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.kg_inference_api_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.kg_inference_api_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

# Target Group definition
resource "aws_lb_target_group" "private_kg_inference_api_tg" {
  name        = "kg-inference-api-tg-private"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  health_check {
    enabled  = true
    path     = "${var.kg_inference_api_base_path}/docs"
    protocol = "HTTP"
  }
  tags = {
    SBO_Billing = "kg_inference_api"
  }
}

resource "aws_lb_listener_rule" "private_kg_inference_api" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 500

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_kg_inference_api_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.kg_inference_api_base_path}/*"]
    }
  }

  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }

  tags = {
    SBO_Billing = "kg_inference_api"
  }
}
