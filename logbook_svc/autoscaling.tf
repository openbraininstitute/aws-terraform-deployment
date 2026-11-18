# scales server tasks on main-thread busy share (loop.busy.pct), 
# not CPU, which missed a full main thread in load tests
resource "aws_appautoscaling_target" "logbook" {
  min_capacity       = var.desired_count
  max_capacity       = var.max_count
  resource_id        = "service/${aws_ecs_cluster.logbook.name}/${aws_ecs_service.logbook_ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  lifecycle {
    precondition {
      condition     = var.max_count >= var.desired_count
      error_message = "logbook_svc_max_count must be at least logbook_svc_desired_count."
    }

    precondition {
      condition     = var.scale_in_busy_pct * 2 < var.scale_out_busy_pct
      error_message = "scale_in_busy_pct must be under half of scale_out_busy_pct."
    }
  }
}

resource "aws_appautoscaling_policy" "logbook_scale_out" {
  name               = "logbook-busy-scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.logbook.resource_id
  scalable_dimension = aws_appautoscaling_target.logbook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.logbook.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    # long enough for the new task to start taking pages, 
    # so one load doesn't add two tasks
    cooldown = 60 # seconds

    # one task per alarm, however far above the level
    step_adjustment {
      metric_interval_lower_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_appautoscaling_policy" "logbook_scale_in" {
  name               = "logbook-busy-scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.logbook.resource_id
  scalable_dimension = aws_appautoscaling_target.logbook.scalable_dimension
  service_namespace  = aws_appautoscaling_target.logbook.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    metric_aggregation_type = "Average"

    # each scale-in reconnects a task's people, so at most two an hour.
    cooldown = 1800 # seconds

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "busy_scale_out" {
  alarm_name        = "logbook-busy-scale-out"
  alarm_description = "The logbook server tasks are busy (average loop.busy.pct at or above the scale-out level for 30 s): autoscaling adds a task"
  namespace         = local.metrics_namespace
  metric_name       = "loop.busy.pct" # one value per task per second, 1 s resolution
  statistic         = "Average"
  dimensions        = local.service_dimension

  # 30 s: long enough to skip a burst like a paste, short because a new task takes minutes.
  period              = 10
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = var.scale_out_busy_pct
  comparison_operator = "GreaterThanOrEqualToThreshold"

  # No metrics is no reason to add tasks.
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_appautoscaling_policy.logbook_scale_out.arn]
}

resource "aws_cloudwatch_metric_alarm" "busy_scale_in" {
  alarm_name        = "logbook-busy-scale-in"
  alarm_description = "The logbook server tasks are idle (average loop.busy.pct at or under the scale-in level for 15 minutes): autoscaling removes a task"
  namespace         = local.metrics_namespace
  metric_name       = "loop.busy.pct"
  statistic         = "Average"
  dimensions        = local.service_dimension

  # Every minute for 15 minutes: truly quiet, not a short lull.
  period              = 60
  evaluation_periods  = 15
  datapoints_to_alarm = 15
  threshold           = var.scale_in_busy_pct
  comparison_operator = "LessThanOrEqualToThreshold"

  # Never remove a task blind.
  treat_missing_data = "notBreaching"

  alarm_actions = [aws_appautoscaling_policy.logbook_scale_in.arn]
}

# Routers scale on average CPU; they all share one page-to-task map, so adding or removing one moves no page.
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

    # Room to spare while a new router starts; a full router slows every page on it.
    target_value       = 60
    scale_out_cooldown = 120  # seconds
    scale_in_cooldown  = 1800 # seconds: each scale-in reconnects that router's sockets
  }
}
