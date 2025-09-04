resource "aws_lb_target_group" "secret_sharing_svc_target_group" {
  name        = "secret-sharing-svc-target-group"
  port        = var.secret_sharing_svc_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    path                = "/"
    port                = var.secret_sharing_svc_port
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
  tags = {
    Name        = "Secret Sharing service Target Group"
    SBO_Billing = "secret_sharing_svc"
  }
}

resource "aws_lb_listener_rule" "secret_sharing_svc_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = var.secret_sharing_svc_listener_rule_priority
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.secret_sharing_svc_target_group.arn
  }

  condition {
    host_header {
      values = [var.secret_sharing_svc_hostname]
    }
  }

  tags = {
    SBO_Billing = "secret_sharing_svc"
  }
}
