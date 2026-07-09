resource "aws_lb_target_group" "accounting_private_tg" {
  #ts:skip=AC_AWS_0492
  name        = "accounting-private"
  port        = 8000
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  lifecycle {
    create_before_destroy = true
  }

  health_check {
    enabled  = true
    path     = "${var.root_path}/health"
    protocol = "HTTP"
  }
}

locals {
  accounting_cidr_chunks = chunklist(var.allowed_source_ip_cidr_blocks, 4)
}

resource "aws_lb_listener_rule" "accounting_private_listener_rule" {
  for_each     = { for i, chunk in local.accounting_cidr_chunks : i => chunk }
  listener_arn = var.private_alb_listener_arn
  priority     = var.listener_rule_base_priority + each.key

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.accounting_private_tg.arn
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }

  condition {
    source_ip {
      values = each.value
    }
  }
}

# Requests to the accounting path that did not match any source_ip allowlist
# rule above are explicitly rejected instead of falling through to the
# listener default action. Priority must stay above the highest possible
# chunk rule (base + chunk_index) and below other services' rules (700+).
resource "aws_lb_listener_rule" "accounting_private_listener_rule_deny" {
  listener_arn = var.private_alb_listener_arn
  priority     = var.listener_rule_base_priority + 40

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "application/json"
      message_body = "{\"detail\": \"Forbidden\"}"
      status_code  = "403"
    }
  }

  condition {
    path_pattern {
      values = ["${var.root_path}*"]
    }
  }
}
