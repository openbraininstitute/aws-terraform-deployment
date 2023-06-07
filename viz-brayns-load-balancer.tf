resource "aws_lb_target_group" "viz_brayns" {
  #ts:skip=AC_AWS_0492
  name        = "viz-brayns"
  port        = 8200
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_brayns_8200" {
  listener_arn = data.terraform_remote_state.common.outputs.private_alb_listener_8200_arn
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
}

resource "aws_route53_record" "private_viz_brayns" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.private_viz_brayns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.private_alb_dns_name]
}
