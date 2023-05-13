
resource "aws_lb_target_group" "embedder" {
  #ts:skip=AC_AWS_0492
  name        = "ml-embedder"
  port        = 3000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id
  #lifecycle {
  #  create_before_destroy = true
  #}
  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_lb_listener_rule" "ml_embedder_3000" {
  listener_arn = data.terraform_remote_state.common.outputs.private_alb_listener_3000_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.embedder.arn
  }

  condition {
    host_header {
      values = [var.private_ml_embedder_hostname]
    }
  }
  tags = {
    SBO_Billing = "machinelearning"
  }
}

resource "aws_route53_record" "private_ml_embedder" {
  zone_id = data.terraform_remote_state.common.outputs.domain_zone_id
  name    = var.private_ml_embedder_hostname
  type    = "CNAME"
  ttl     = 60
  records = [data.terraform_remote_state.common.outputs.private_alb_dns_name]
}
