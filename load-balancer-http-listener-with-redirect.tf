resource "aws_lb_listener" "sbo_http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }

  tags = {
    SBO_Billing = "common"
  }

  depends_on = [
    aws_lb.alb
  ]
}
