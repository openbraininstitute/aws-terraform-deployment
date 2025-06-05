# Configure ALB target group
resource "aws_lb_target_group" "private_jupyterhub_target_group" {
  name        = var.jupyterhub_target_group_name
  port        = var.jupyterhub_nginx_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "Private JupyterHub Target Group"
    SBO_Billing = "jupyterhub_svc"
  }
  health_check {
    path                = var.jupyterhub_base_path
    port                = var.jupyterhub_nginx_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group_attachment" "private_jupyterhub_target_group_attachment" {
  target_group_arn = aws_lb_target_group.private_jupyterhub_target_group.arn
  target_id        = aws_instance.jupyterhub_server.id
  port             = var.jupyterhub_nginx_port
}

resource "aws_lb_listener_rule" "private_jupyterhub_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = var.jupyterhub_listener_rule_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_jupyterhub_target_group.arn
  }

  condition {
    path_pattern {
      values = ["${var.jupyterhub_base_path}*"]
    }
  }

  tags = {
    SBO_Billing = "jupyterhub_svc"
  }
}
