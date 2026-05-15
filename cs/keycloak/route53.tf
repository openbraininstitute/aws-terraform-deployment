data "aws_lb_listener" "private_alb" {
  arn = var.private_alb_https_listener_arn
}

data "aws_lb" "private_alb" {
  arn = data.aws_lb_listener.private_alb.load_balancer_arn
}

resource "aws_route53_record" "keycloak_admin_private" {
  zone_id = var.cell_a_private_zone_id
  name    = var.keycloak_admin_hostname
  type    = "A"

  alias {
    name                   = data.aws_lb.private_alb.dns_name
    zone_id                = data.aws_lb.private_alb.zone_id
    evaluate_target_health = true
  }
}
