# Configure ALB target group
resource "aws_lb_target_group" "private_jupyterhub_target_group" {
  name        = "private-jupyterhub-target-group"
  port        = var.jupyterhub_port
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "Private JupyterHub Target Group"
    SBO_Billing = "jupyterhub_svc"
  }
  health_check {
    path                = "/"
    port                = var.jupyterhub_port
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
  port             = var.jupyterhub_port
}

resource "aws_lb_listener_rule" "private_jupyterhub_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 100
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_jupyterhub_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/hub*"]
    }
  }

  tags = {
    SBO_Billing = "jupyterhub_svc"
  }
}
