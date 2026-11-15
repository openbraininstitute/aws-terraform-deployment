resource "aws_lb_target_group" "logbook_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "logbook-private"
  port        = local.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # Lets an agent POST finish (5 s save + 3 s EntityCore call); the 300 s default would slow every deploy.
  deregistration_delay = 20

  # No stickiness: WebSockets stay on one task, Redis relays changes, and page affinity is the router's job.

  lifecycle {
    create_before_destroy = true
  }

  # /healthz, not /readyz: a Postgres or Redis outage must not make ECS replace every task.
  # Health checks skip the listener rule, so the path needs the base path.
  health_check {
    enabled             = true
    path                = "${var.base_path}/healthz"
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2  # 2 x 15 s: a new task takes traffic after about 30 s
    unhealthy_threshold = 3  # 3 x 15 s: a hung task leaves within 45 s
    interval            = 15 # seconds
    timeout             = 5  # seconds; /healthz touches no dependency, answers in ms
  }
}

resource "aws_lb_listener_rule" "logbook_private_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.logbook_private_tg.arn
  }

  # Two patterns, not "${base_path}*", so a future /api/logbooks service isn't caught here.
  condition {
    path_pattern {
      values = [var.base_path, "${var.base_path}/*"]
    }
  }
}

# Targets are the page routers, not the server tasks; they send each page to one task.
resource "aws_lb_target_group" "logbook_router_tg" {
  #ts:skip=AC_AWS_0492
  name        = "logbook-router"
  port        = local.router_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # Same 20 s as the tasks; browsers then reconnect through another router, which picks the same task.
  deregistration_delay = 20

  # No stickiness: the router's hash is the affinity.

  lifecycle {
    create_before_destroy = true
  }

  # The router's own alive check needs no server task, so routers stay in while the tasks change.
  health_check {
    enabled             = true
    path                = "${var.base_path}/routerz" # must match haproxy.cfg
    protocol            = "HTTP"
    matcher             = "200"
    healthy_threshold   = 2  # 2 x 15 s
    unhealthy_threshold = 3  # 3 x 15 s
    interval            = 15 # seconds
    timeout             = 5  # seconds
  }
}

# Page paths go to the router, the rest falls to the rule above, so this priority must be lower.
# The paths must match the page ACL in haproxy.cfg.
resource "aws_lb_listener_rule" "logbook_router_listener_rule" {
  listener_arn = var.private_alb_listener_arn
  priority     = var.router_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.logbook_router_tg.arn
  }

  condition {
    path_pattern {
      values = [
        "${var.base_path}/v1/collaboration/*",
        "${var.base_path}/v1/page/*",
      ]
    }
  }

  # A precondition: cross-variable validations need Terraform 1.9, and this repo supports >= 1.2.
  lifecycle {
    precondition {
      condition     = var.router_listener_rule_priority < var.alb_listener_rule_priority
      error_message = "router_listener_rule_priority must be lower than alb_listener_rule_priority, or the page paths never reach the router."
    }
  }
}
