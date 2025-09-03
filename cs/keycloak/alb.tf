#  Configure ALB target group
resource "aws_lb_target_group" "private_keycloak_target_group" {
  name        = "private-keycloak-target-group"
  port        = var.keycloak_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  tags = {
    Name        = "Private Keycloak Target Group"
    SBO_Billing = "keycloak"
  }
  health_check {
    path                = "/auth/health/ready"
    port                = var.keycloak_management_port
    protocol            = "HTTP"
    interval            = 60
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_listener_rule" "private_keycloak_https" {
  listener_arn = var.private_alb_https_listener_arn
  priority     = 565
  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.private_keycloak_target_group.arn
  }

  condition {
    path_pattern {
      values = ["/auth*"]
    }
  }
  condition {
    source_ip {
      values = var.allowed_source_ip_cidr_blocks
    }
  }
  tags = {
    SBO_Billing = "keycloak"
  }
}
