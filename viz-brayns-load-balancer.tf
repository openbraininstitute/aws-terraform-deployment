resource "aws_route53_record" "brayns" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.viz_brayns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.private_alb_dns_name]
}


resource "aws_lb_target_group" "viz_brayns" {
  #ts:skip=AC_AWS_0492
  name_prefix = "brayns"
  port        = 5000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  health_check {
    path = "/healthz"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_brayns_5000" {
  listener_arn = data.terraform_remote_state.common.outputs.private_alb_listener_5000_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_brayns.arn
  }

  condition {
    host_header {
      values = [var.viz_brayns_hostname]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_target_group" "viz_bcsb" {
  #ts:skip=AC_AWS_0492
  name_prefix = "bcsb"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  health_check {
    path = "/healthz"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "viz"
  }
}

resource "aws_lb_listener_rule" "viz_bcsb_8000" {
  listener_arn = data.terraform_remote_state.common.outputs.private_alb_listener_8000_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.viz_bcsb.arn
  }

  condition {
    host_header {
      values = [var.viz_brayns_hostname]
    }
  }
  tags = {
    SBO_Billing = "viz"
  }
}
