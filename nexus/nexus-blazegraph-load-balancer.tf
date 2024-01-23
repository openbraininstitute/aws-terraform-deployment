resource "aws_lb_target_group" "blazegraph" {
  #ts:skip=AC_AWS_0492
  name_prefix = "blzgrp"
  port        = 9999
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id
  health_check {
    enabled  = true
    path     = "/blazegraph/"
    protocol = "HTTP"
  }
  lifecycle {
    create_before_destroy = true
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_lb_listener_rule" "blazegraph_9999" {
  listener_arn = var.private_alb_listener_9999_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.blazegraph.arn
  }

  condition {
    host_header {
      values = [var.private_blazegraph_hostname]
    }
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}

resource "aws_route53_record" "private_blazegraph" {
  zone_id = var.domain_zone_id
  name    = var.private_blazegraph_hostname
  type    = "CNAME"
  ttl     = 60
  records = [var.private_alb_dns_name]
}