# Alarms that warn before users feel a limit. No Container Insights here (it is off), so no shared ECS module.
# They read the Service series (all tasks), so Maximum means the worst task and p95 is over all tasks.

locals {
  metrics_namespace = "Logbook/Server" # must match the server's metrics namespace

  # Must match the server's service name, or every alarm below goes quiet.
  service_dimension = { Service = "logbook-server" }

  alarm_actions = [aws_sns_topic.logbook_alarms.arn]
}

resource "aws_sns_topic" "logbook_alarms" {
  name = "ecs-logbook_svc-alerts"
}

# --- The task: CPU and memory (AWS/ECS, no Container Insights) ---

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "logbook-cpu-high"
  alarm_description   = "A logbook task is above 70 % CPU for 5 minutes, near its limit."
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Maximum" # meant as the hottest task; not checked yet, verify on staging
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  threshold           = 70
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    ClusterName = aws_ecs_cluster.logbook.name
    ServiceName = aws_ecs_service.logbook_ecs_service.name
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "logbook-memory-high"
  alarm_description   = "A logbook task uses more than 75 % of its memory."
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Maximum" # meant as the fullest task; not checked yet, verify on staging
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  # Memory jumps in big steps (a merge worker is about 510 MB), so warn well before the kill at 100 %.
  threshold           = 75
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    ClusterName = aws_ecs_cluster.logbook.name
    ServiceName = aws_ecs_service.logbook_ecs_service.name
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

# --- Saving and the event loop (server metrics, Service dimension) ---

resource "aws_cloudwatch_metric_alarm" "unsaved_age_high" {
  alarm_name          = "logbook-unsaved-age-high"
  alarm_description   = "The oldest unsaved change is over 3 s old for 2 minutes: saving is falling behind."
  namespace           = local.metrics_namespace
  metric_name         = "unsaved.age.ms" # a gauge, every 10 s
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 2
  datapoints_to_alarm = 2
  threshold           = 3000 # ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = local.service_dimension

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "flush_slow" {
  alarm_name          = "logbook-flush-slow"
  alarm_description   = "The p95 save time is above 1 s for 3 minutes: the database or event loop is slow."
  namespace           = local.metrics_namespace
  metric_name         = "flush.ms"
  extended_statistic  = "p95"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 3
  threshold           = 1000 # ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching" # no save in a minute writes no value
  dimensions          = local.service_dimension

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "loop_delay_high" {
  alarm_name          = "logbook-loop-delay-high"
  alarm_description   = "The p99 event-loop delay is above 100 ms for 5 minutes: the server is running late."
  namespace           = local.metrics_namespace
  metric_name         = "loop.delay.ms" # one median a second per task
  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  # Half the shedding limit (shed_loop_delay_ms = 200), so it warns before a task refuses work.
  threshold           = 100 # ms
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"
  dimensions          = local.service_dimension

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "load_shed" {
  alarm_name          = "logbook-load-shed"
  alarm_description   = "A logbook task is refusing new work to protect itself (load shedding)."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  treat_missing_data  = "notBreaching" # a counter is written only when it is not zero

  metric_query {
    id          = "upgrades"
    return_data = false

    metric {
      namespace   = local.metrics_namespace
      metric_name = "shed.upgrades"
      period      = 60
      stat        = "Sum"
      dimensions  = local.service_dimension
    }
  }

  metric_query {
    id          = "joins"
    return_data = false

    metric {
      namespace   = local.metrics_namespace
      metric_name = "shed.joins"
      period      = 60
      stat        = "Sum"
      dimensions  = local.service_dimension
    }
  }

  metric_query {
    id          = "writes"
    return_data = false

    metric {
      namespace   = local.metrics_namespace
      metric_name = "shed.writes"
      period      = 60
      stat        = "Sum"
      dimensions  = local.service_dimension
    }
  }

  metric_query {
    id          = "shed"
    expression  = "FILL(upgrades, 0) + FILL(joins, 0) + FILL(writes, 0)"
    label       = "Requests refused by load shedding"
    return_data = true
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

# --- Merges and the Yjs worker ---

resource "aws_cloudwatch_metric_alarm" "worker_queue_full" {
  alarm_name          = "logbook-worker-queue-full"
  alarm_description   = "A task's Yjs merge queue is full: merges wait and agent changes get 503."
  namespace           = local.metrics_namespace
  metric_name         = "worker.queued" # a gauge, every 10 s
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  # Must match the server's WORKERS_YJS_QUEUE_MAX default.
  threshold           = 16
  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  dimensions          = local.service_dimension

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "merge_failed" {
  alarm_name          = "logbook-merge-failed"
  alarm_description   = "A logbook page could not be merged; the next sweep tries again."
  namespace           = local.metrics_namespace
  metric_name         = "merge.failed"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  datapoints_to_alarm = 1
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching" # a counter is written only when it is not zero
  dimensions          = local.service_dimension

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}

# --- Agent writes that time out (503 share of POST content) ---
# Read from the server's request log line (the ALB counts 5xx for all routes); renamed fields make it go quiet.

locals {
  content_write_pattern = "$.event = \"request\" && $.method = \"POST\" && $.route = \"${var.base_path}/v1/page/:pageId/content\""
}

resource "aws_cloudwatch_log_metric_filter" "content_writes" {
  name           = "logbook-content-writes"
  log_group_name = aws_cloudwatch_log_group.logbook_ecs_task_logs.name
  pattern        = "{ ${local.content_write_pattern} }"

  metric_transformation {
    namespace = local.metrics_namespace
    name      = "content.writes"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_log_metric_filter" "content_writes_unavailable" {
  name           = "logbook-content-writes-unavailable"
  log_group_name = aws_cloudwatch_log_group.logbook_ecs_task_logs.name
  pattern        = "{ ${local.content_write_pattern} && $.status = 503 }"

  metric_transformation {
    namespace = local.metrics_namespace
    name      = "content.writes.unavailable"
    value     = "1"
    unit      = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "agent_write_unavailable" {
  alarm_name          = "logbook-agent-write-unavailable"
  alarm_description   = "More than 1 % of agent content writes answer 503: they time out or are refused."
  comparison_operator = "GreaterThanThreshold"
  threshold           = 1 # %
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  treat_missing_data  = "notBreaching" # no write in a minute writes no value

  metric_query {
    id          = "writes"
    return_data = false

    metric {
      namespace   = local.metrics_namespace
      metric_name = aws_cloudwatch_log_metric_filter.content_writes.metric_transformation[0].name
      period      = 60
      stat        = "Sum"
    }
  }

  metric_query {
    id          = "unavailable"
    return_data = false

    metric {
      namespace   = local.metrics_namespace
      metric_name = aws_cloudwatch_log_metric_filter.content_writes_unavailable.metric_transformation[0].name
      period      = 60
      stat        = "Sum"
    }
  }

  # Needs at least 20 writes a minute, so one 503 at low traffic doesn't fire it.
  metric_query {
    id          = "share"
    expression  = "IF(FILL(writes, 0) >= 20, 100 * FILL(unavailable, 0) / FILL(writes, 1), 0)"
    label       = "Share of content writes answered 503 (%)"
    return_data = true
  }

  alarm_actions             = local.alarm_actions
  ok_actions                = local.alarm_actions
  insufficient_data_actions = local.alarm_actions
}
