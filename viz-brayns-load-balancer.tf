resource "aws_lb_listener" "sbo_brayns" {
  load_balancer_arn = aws_lb.alb.arn
  port              = "8200"
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content: working"
      status_code  = "200"
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
  depends_on = [
    aws_lb.alb
  ]
}

resource "aws_lb_target_group" "viz_brayns" {
  #ts:skip=AC_AWS_0492
  name        = "viz-brayns"
  port        = 8200
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_brayns_8200" {
  listener_arn = aws_lb_listener.sbo_brayns.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_brayns.arn
  }

  condition {
    host_header {
      values = [var.private_viz_brayns_hostname]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
  depends_on = [
    aws_lb_listener.sbo_brayns,
    aws_lb.alb
  ]
}

resource "aws_route53_record" "private_viz_brayns" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.private_viz_brayns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.private_alb_dns_name]
}
