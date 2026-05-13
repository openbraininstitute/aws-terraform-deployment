resource "aws_cloudwatch_metric_alarm" "ecs_service_memory_high" {
  alarm_name          = "ecs-${var.short_name}-memory-high"
  alarm_description   = "ECS service ${var.short_name} memory utilization is above ${var.ecs_service_memory_high_threshold}%"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "MemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.ecs_service_memory_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    ClusterName = var.ecs_cluster_name
    ServiceName = var.ecs_service_name
  }

  alarm_actions             = [aws_sns_topic.ecs_alerts.arn]
  ok_actions                = [aws_sns_topic.ecs_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.ecs_alerts.arn]
  tags                      = { SBO_Billing = var.sbo_billing_tag }
}

resource "aws_cloudwatch_metric_alarm" "ecs_container_memory_high" {
  for_each = toset(var.ecs_container_names_memory_alarm)

  alarm_name          = "ecs-${var.short_name}-${each.key}-container-memory-high"
  alarm_description   = "ECS container ${each.key} in ${var.short_name} memory utilization is above ${var.ecs_container_memory_high_threshold}%"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "ContainerMemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.ecs_container_memory_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    ClusterName          = var.ecs_cluster_name
    TaskDefinitionFamily = var.ecs_task_definition_name
    ContainerName        = each.key
  }

  alarm_actions             = [aws_sns_topic.ecs_alerts.arn]
  ok_actions                = [aws_sns_topic.ecs_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.ecs_alerts.arn]
  tags                      = { SBO_Billing = var.sbo_billing_tag }
}

resource "aws_cloudwatch_metric_alarm" "ecs_running_tasks_below_desired" {
  alarm_name          = "ecs-${var.short_name}-running-tasks-below-desired"
  alarm_description   = "ECS running task count is below desired task count"
  comparison_operator = "LessThanThreshold"
  threshold           = 0
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  treat_missing_data  = "breaching"

  metric_query {
    id          = "running"
    return_data = false

    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "RunningTaskCount"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "desired"
    return_data = false

    metric {
      namespace   = "ECS/ContainerInsights"
      metric_name = "DesiredTaskCount"
      period      = 60
      stat        = "Average"

      dimensions = {
        ClusterName = var.ecs_cluster_name
        ServiceName = var.ecs_service_name
      }
    }
  }

  metric_query {
    id          = "task_deficit"
    expression  = "running - desired"
    label       = "Running minus desired task count"
    return_data = true
  }

  alarm_actions             = [aws_sns_topic.ecs_alerts.arn]
  ok_actions                = [aws_sns_topic.ecs_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.ecs_alerts.arn]
  tags                      = { SBO_Billing = var.sbo_billing_tag }
}

resource "aws_cloudwatch_metric_alarm" "ecs_task_memory_high" {
  alarm_name          = "ecs-${var.short_name}-task-memory-high"
  alarm_description   = "ECS task ${var.short_name} memory utilization is above ${var.ecs_task_memory_high_threshold}%"
  namespace           = "ECS/ContainerInsights"
  metric_name         = "TaskMemoryUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.ecs_task_memory_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    ClusterName          = var.ecs_cluster_name
    TaskDefinitionFamily = var.ecs_task_definition_name
  }

  alarm_actions             = [aws_sns_topic.ecs_alerts.arn]
  ok_actions                = [aws_sns_topic.ecs_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.ecs_alerts.arn]
  tags                      = { SBO_Billing = var.sbo_billing_tag }
}

