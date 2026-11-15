resource "aws_lb_target_group" "logbook_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "logbook-private"
  port        = local.container_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # ECS deregisters a task and waits this long before it sends SIGTERM.
  # During the wait the ALB sends no new request to the task; at the end
  # it closes the WebSockets still open, and the browser reconnects to
  # another task (measured in the server repo: about 1 s; unsaved edits
  # are kept in the browser's IndexedDB). 20 s lets an agent POST in
  # flight finish: it waits at most STORE_FLUSHED_TIMEOUT_MS (5 s) plus
  # one EntityCore call (ENTITYCORE_CALL_TIMEOUT_MS, 3 s). The AWS
  # default (300 s) would keep every deploy waiting 5 minutes per task.
  deregistration_delay = 20

  # No stickiness: a WebSocket stays on its task for its whole life, the
  # Hocuspocus Redis extension relays changes between tasks, and agent
  # HTTPS calls are stateless. Page affinity is the page router's work
  # (router.tf): page paths reach the tasks through it, by Cloud Map, not
  # through this group.

  lifecycle {
    create_before_destroy = true
  }

  # Health checks go straight to the target, without the listener rule,
  # so the path carries the base path. Liveness (/healthz), not readiness
  # (/readyz): /readyz answers 503 while Postgres or Redis is down, ECS
  # would then replace every task, and each replaced task would drop the
  # live sessions the server is built to keep during such an outage.
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

  # No path rewrite: the server mounts every route under SERVER_BASE_PATH.
  # Two patterns, not "${base_path}*", so a future /api/logbooks
  # service is not shadowed.
  condition {
    path_pattern {
      values = [var.base_path, "${var.base_path}/*"]
    }
  }
}

# The page router's target group (router.tf). The routers, not the server
# tasks, are its targets; they hash each page to one task.
resource "aws_lb_target_group" "logbook_router_tg" {
  #ts:skip=AC_AWS_0492
  name        = "logbook-router"
  port        = local.router_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  # A stopping router: the ALB sends it nothing new and, at the end,
  # closes its open WebSockets; each browser reconnects through another
  # router, which hashes the page to the same task. 20 s, as the tasks'
  # group: an agent call in flight finishes.
  deregistration_delay = 20

  # No stickiness: the router's hash is the affinity.

  lifecycle {
    create_before_destroy = true
  }

  # The router's own liveness (monitor-uri in haproxy.cfg), which needs no
  # server task: a router stays in while the tasks change.
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

# Page traffic goes through the router; everything else (the bare
# /v1/collaboration of older tabs, research calls, health) stays on the
# rule above, round robin straight to the tasks. The ALB tries the lowest
# number first, so this rule's priority is below the one above.
# The paths match haproxy.cfg's page ACL; a page id is one path segment.
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

  # A precondition, not a variable validation: a validation that reads another
  # variable needs Terraform 1.9, and this repository supports >= 1.2.
  lifecycle {
    precondition {
      condition     = var.router_listener_rule_priority < var.alb_listener_rule_priority
      error_message = "router_listener_rule_priority must be lower than alb_listener_rule_priority, or the page paths never reach the router."
    }
  }
}
