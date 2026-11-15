# CloudWatch alarms of the logbook server: the list of log-book
# deployment.md section 9, which shows the limit before people feel it.
#
# Same pattern as the shared alarm modules (ecs_container_cloudwatch_metric_alarms,
# rds_postgresql_cloudwatch_metric_alarms): 60 s periods, and alarm, ok and
# insufficient-data actions to one SNS topic, which monitoring.tf sends to
# Teams and to a debug queue. One deviation, on purpose: the alarms live in
# this module, not in a shared one. They read the server's own metrics, they
# share the module's count gate (logbook_enabled), and they carry the
# SBO_Billing tag of the aws.logbook provider.
#
# Container Insights stays off on this cluster (backend.tf), so no alarm here
# reads ECS/ContainerInsights; that is also why the shared ECS module is not
# used (3 of its 4 alarms read it, and its running-tasks alarm would sit in
# ALARM for ever with no data). AWS/ECS CPU and memory need no Container
# Insights.
#
# The server metrics (namespace Logbook/Server) come from the embedded-metric
# lines of the log (log-book apps/server/src/infra/telemetry/metrics.ts).
# Every metric has two dimension sets: TaskId (new at every start, so no
# alarm can follow it) and Service, one series for all tasks, which these
# alarms read. So a Maximum is the worst task, and a p95 is over all tasks.
#
# Not here: the log event process.unhandled-rejection is logged at error
# level and already reaches Teams through the error-log subscription
# (monitoring.tf, module logbook_cloudwatch_error_log_entries_to_sns).

locals {
  metrics_namespace = "Logbook/Server" # NAMESPACE in metrics.ts

  # SERVICE_NAME in log-book apps/server/src/infra/telemetry/logger.ts:
  # change both, or every alarm below goes quiet.
  service_dimension = { Service = "logbook-server" }

  alarm_actions = [aws_sns_topic.logbook_alarms.arn]
}

resource "aws_sns_topic" "logbook_alarms" {
  name = "ecs-logbook_svc-alerts"
}

# --- The task: CPU and memory (AWS/ECS, no Container Insights) ---

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "logbook-cpu-high"
  alarm_description   = "A logbook server task uses more than 70 % CPU for 5 minutes: near its limit (about 1.0 core, log-book deployment.md 5.1); autoscaling may not keep up"
  namespace           = "AWS/ECS"
  metric_name         = "CPUUtilization"
  statistic           = "Maximum" # assumed to be the hottest task (with page affinity one hot task matters); check on staging
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
  alarm_description   = "A logbook server task uses more than 75 % of its memory"
  namespace           = "AWS/ECS"
  metric_name         = "MemoryUtilization"
  statistic           = "Maximum" # assumed to be the fullest task; check on staging
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  # 75 %: a stalled reader can hold up to LIVE_BACKPRESSURE_LIMIT_BYTES
  # (24 MB) and a merge worker up to about 510 MB, so memory moves in
  # steps; the alarm must fire before the task is killed at 100 %.
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
  alarm_description   = "The oldest unsaved change of a logbook task is older than 3 s for 2 minutes: saving falls behind (healthy: 1 to 2.4 s measured)"
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
  alarm_description   = "The p95 of the logbook saves (flush.ms) is above 1 s for 3 minutes: the database or the event loop is slow (healthy: 428 ms at 200 busy pages)"
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
  alarm_description   = "The p99 of the logbook event-loop medians (loop.delay.ms) is above 100 ms for 5 minutes: the event loop runs late, the earliest sign of the limit"
  namespace           = local.metrics_namespace
  metric_name         = "loop.delay.ms" # one median a second per task
  extended_statistic  = "p99"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 5
  # Half the shedding limit (shed_loop_delay_ms, 200): it warns before a
  # task starts to refuse work.
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
  alarm_description   = "A logbook task refuses new work (load shedding: new sockets, joins or agent writes), log-book deployment.md 6.4"
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
  alarm_description   = "The Yjs worker queue of a logbook task is full: merges are deferred and agent changes get 503"
  namespace           = local.metrics_namespace
  metric_name         = "worker.queued" # a gauge, every 10 s
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  # The server's WORKERS_YJS_QUEUE_MAX default (log-book apps/server/.env.example):
  # change both together.
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
  alarm_description   = "A logbook page could not be merged (merge.failed); the next sweep tries it again"
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
#
# From the server's `request` log line (log-book apps/server/src/core/request-log.ts):
# the fields event, method, route and status, and the route string. A rename
# there makes this alarm go quiet (notBreaching), not fire. The ALB cannot
# give this: page paths reach the tasks through the router (router.tf), and
# the ALB counts 5xx for every route together.

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
  alarm_description   = "More than 1 % of the agents' content writes (POST /v1/page/:pageId/content) answer 503: they time out or are refused (run g, failing step: 1,774 of 3,372 POSTs, 53 %)"
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

  # At least 20 writes a minute, so one 503 at low traffic does not fire it.
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
