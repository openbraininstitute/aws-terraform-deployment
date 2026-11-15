# Autoscaling of the server tasks (pattern: target tracking, as
# small_scale_simulator/ecs.tf). App Auto Scaling owns the task count:
# aws_ecs_service ignores changes to desired_count (backend.tf), and
# desired_count is the floor here.
#
# Landed with the page router (router.tf) on purpose: without page affinity
# more tasks carry less (log-book deployment.md 5.1: every task loads every
# busy page and every change crosses Redis to all of them), so a CPU target
# would push itself to the maximum. With the router a page lives on one
# task, and a task more is capacity more (deployment.md 6.1).
#
# Cost of every step, in both directions: consistent hashing moves about
# 1/N of the pages to another task, and their sockets reconnect (about 1 s;
# the browser keeps unsaved edits in IndexedDB). So scale-in is slow on
# purpose, and scale-out is quick because a task at its limit loses saves.

resource "aws_appautoscaling_target" "logbook" {
  min_capacity       = var.desired_count
  max_capacity       = var.max_count
  resource_id        = "service/${aws_ecs_cluster.logbook.name}/${aws_ecs_service.logbook_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  # A precondition, not a validation on max_count: a validation that reads
  # another variable needs Terraform 1.9, and the repository asks for >= 1.2.
  lifecycle {
    precondition {
      condition     = var.max_count >= var.desired_count
      error_message = "logbook_svc_max_count must be at least logbook_svc_desired_count."
    }
  }
}

resource "aws_appautoscaling_policy" "logbook_cpu" {
  name               = "logbook-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.logbook.resource_id
  scalable_dimension = aws_appautoscaling_target.logbook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.logbook.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    # A task fails at about 1.0 core of its 1 vCPU (deployment.md 5.1). 60 %
    # leaves room for the 2 to 3 minutes a new task needs (image pull, the
    # migrate init container, 2 x 15 s health checks) while the load grows.
    target_value = 60

    # Short: a task at its limit falls behind on saves. During the cooldown a
    # second scale-out happens only if it asks for more than the first, so a
    # task that is still starting is not added twice.
    scale_out_cooldown = 120 # seconds

    # 30 minutes: each scale-in stops a task (the graceful stop of a deploy:
    # deregistration 20 s, stopTimeout 40 s) and moves its pages; at most two
    # an hour, after target tracking's own slow low alarm (about 15 minutes
    # under the target).
    scale_in_cooldown = 1800 # seconds
  }
}

# Autoscaling of the page routers (router.tf), the same pattern. A router's
# CPU follows the typing on the pages it carries (deployment.md 6.8), and
# the ALB spreads page traffic round robin over the routers, so their
# average CPU is the signal. Every router builds the same ring, so a router
# more or less moves no page; a scale-in closes that router's sockets, which
# reconnect through another router to the same task (about 1 s).
resource "aws_appautoscaling_target" "logbook_router" {
  min_capacity       = var.router_desired_count
  max_capacity       = var.router_max_count
  resource_id        = "service/${aws_ecs_cluster.logbook.name}/${aws_ecs_service.logbook_router.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    precondition {
      condition     = var.router_max_count >= var.router_desired_count
      error_message = "router_max_count must be at least router_desired_count."
    }
  }
}

resource "aws_appautoscaling_policy" "logbook_router_cpu" {
  name               = "logbook-router-cpu-target-tracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.logbook_router.resource_id
  scalable_dimension = aws_appautoscaling_target.logbook_router.scalable_dimension
  service_namespace  = aws_appautoscaling_target.logbook_router.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    # As the server's: room for the minutes a new router needs while the
    # typing grows. A router at its quota slows every page it carries.
    target_value       = 60
    scale_out_cooldown = 120  # seconds
    scale_in_cooldown  = 1800 # seconds: each scale-in reconnects that router's sockets
  }
}
