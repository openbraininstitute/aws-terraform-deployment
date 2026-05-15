resource "aws_cloudwatch_metric_alarm" "rds_cpu_high" {
  alarm_name          = "rds-${var.short_name}-cpu-high"
  alarm_description   = "RDS instance ${var.short_name} CPU utilization is above ${var.cpu_utilization_high_threshold}%"
  namespace           = "AWS/RDS"
  metric_name         = "CPUUtilization"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.cpu_utilization_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_freeable_memory_low" {
  alarm_name          = "rds-${var.short_name}-freeable-memory-low"
  alarm_description   = "RDS instance ${var.short_name} freeable memory is below ${var.freeable_memory_low_threshold} bytes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeableMemory"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.freeable_memory_low_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_free_storage_space_low" {
  alarm_name          = "rds-${var.short_name}-free-storage-space-low"
  alarm_description   = "RDS instance ${var.short_name} free storage space is below ${var.free_storage_space_low_threshold} bytes"
  namespace           = "AWS/RDS"
  metric_name         = "FreeStorageSpace"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 3
  datapoints_to_alarm = 2
  threshold           = var.free_storage_space_low_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_database_connections_high" {
  alarm_name          = "rds-${var.short_name}-database-connections-high"
  alarm_description   = "RDS instance ${var.short_name} database connections are above ${var.database_connections_high_threshold}"
  namespace           = "AWS/RDS"
  metric_name         = "DatabaseConnections"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.database_connections_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_read_latency_high" {
  alarm_name          = "rds-${var.short_name}-read-latency-high"
  alarm_description   = "RDS instance ${var.short_name} read latency is above ${var.read_latency_high_threshold}s"
  namespace           = "AWS/RDS"
  metric_name         = "ReadLatency"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.read_latency_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_write_latency_high" {
  alarm_name          = "rds-${var.short_name}-write-latency-high"
  alarm_description   = "RDS instance ${var.short_name} write latency is above ${var.write_latency_high_threshold}s"
  namespace           = "AWS/RDS"
  metric_name         = "WriteLatency"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.write_latency_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_swap_usage_high" {
  alarm_name          = "rds-${var.short_name}-swap-usage-high"
  alarm_description   = "RDS instance ${var.short_name} swap usage is above ${var.swap_usage_high_threshold} bytes"
  namespace           = "AWS/RDS"
  metric_name         = "SwapUsage"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.swap_usage_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_disk_queue_depth_high" {
  alarm_name          = "rds-${var.short_name}-disk-queue-depth-high"
  alarm_description   = "RDS instance ${var.short_name} disk queue depth is above ${var.disk_queue_depth_high_threshold}"
  namespace           = "AWS/RDS"
  metric_name         = "DiskQueueDepth"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.disk_queue_depth_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_credit_balance_low" {
  count = var.enable_cpu_credit_alarms ? 1 : 0

  alarm_name          = "rds-${var.short_name}-cpu-credit-balance-low"
  alarm_description   = "RDS instance ${var.short_name} CPU credit balance is below ${var.cpu_credit_balance_low_threshold}"
  namespace           = "AWS/RDS"
  metric_name         = "CPUCreditBalance"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.cpu_credit_balance_low_threshold
  comparison_operator = "LessThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}

resource "aws_cloudwatch_metric_alarm" "rds_cpu_surplus_credit_balance_high" {
  count = var.enable_cpu_credit_alarms ? 1 : 0

  alarm_name          = "rds-${var.short_name}-cpu-surplus-credit-balance-high"
  alarm_description   = "RDS instance ${var.short_name} CPU surplus credit balance is above ${var.cpu_surplus_credit_balance_high_threshold}, indicating borrowed credits in unlimited mode"
  namespace           = "AWS/RDS"
  metric_name         = "CPUSurplusCreditBalance"
  statistic           = "Average"
  period              = 60
  evaluation_periods  = 5
  datapoints_to_alarm = 3
  threshold           = var.cpu_surplus_credit_balance_high_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    DBInstanceIdentifier = var.db_instance_identifier
  }

  alarm_actions             = [aws_sns_topic.rds_alerts.arn]
  ok_actions                = [aws_sns_topic.rds_alerts.arn]
  insufficient_data_actions = [aws_sns_topic.rds_alerts.arn]
}
