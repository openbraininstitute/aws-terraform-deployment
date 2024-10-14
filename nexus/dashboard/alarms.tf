#tfsec:ignore:aws-sns-enable-topic-encryption
resource "aws_sns_topic" "nexus_alerts" {
  name = "nexus_alerts_sns_topic"
}

resource "aws_sns_topic_subscription" "nexus_alerts_erik_heeren" {
  topic_arn = aws_sns_topic.nexus_alerts.arn
  endpoint  = "erik.heeren@epfl.ch"
  protocol  = "email"
}

resource "aws_sns_topic_subscription" "nexus_alerts_jdc" {
  topic_arn = aws_sns_topic.nexus_alerts.arn
  endpoint  = "jean-denis.courcol@epfl.ch"
  protocol  = "email"
}

resource "aws_sns_topic_subscription" "nexus_alerts_nise" {
  topic_arn = aws_sns_topic.nexus_alerts.arn
  endpoint  = "bbp-ou-nise@groupes.epfl.ch"
  protocol  = "email"
}

resource "aws_cloudwatch_metric_alarm" "blazegraph-search-cpu-alarm" {
  alarm_name                = "blazegraph-search-cpu-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 90
  alarm_description         = "CPU utilization for Blazegraph Search"
  insufficient_data_actions = []
  alarm_actions             = ["arn:aws:sns:us-east-1:671250183987:sns_no_reply_openbrainplatform_org", aws_sns_topic.nexus_alerts.arn]
  dimensions = {
    ServiceName = "blazegraph-obp-composite-4_ecs_service"
    ClusterName = "nexus_ecs_cluster"
  }
}

resource "aws_cloudwatch_log_metric_filter" "blazegraph-query-timeout-metric" {
  name           = "blazegraph-query-timeout-exception"
  pattern        = "com.bigdata.bop.engine.QueryTimeoutException"
  log_group_name = "blazegraph-obp-composite-4_app"

  metric_transformation {
    name          = "QueryTimeoutException"
    namespace     = "blazegraph"
    default_value = "0"
    value         = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "blazegraph-out-of-memory-error-metric" {
  name           = "blazegraph-out-of-memory-error"
  pattern        = "java.lang.OutOfMemoryError"
  log_group_name = "blazegraph-obp-composite-4_app"

  metric_transformation {
    name          = "OutOfMemoryError"
    namespace     = "blazegraph"
    default_value = "0"
    value         = "1"
  }
}

resource "aws_cloudwatch_log_metric_filter" "blazegraph-test-log-metric" {
  name           = "blazegraph-test-log"
  pattern        = "DatasetNotFoundException"
  log_group_name = "blazegraph-obp-composite-4_app"

  metric_transformation {
    name          = "TestLogMetric"
    namespace     = "blazegraph"
    default_value = "0"
    value         = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "blazegraph-search-query-timeout-alarm" {
  alarm_name                = "blazegraph-search-query-timeout-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = aws_cloudwatch_log_metric_filter.blazegraph-query-timeout-metric.name
  namespace                 = "blazegraph"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 0
  alarm_description         = "QueryTimeoutExceptions for Blazegraph Search"
  insufficient_data_actions = []
  alarm_actions             = ["arn:aws:sns:us-east-1:671250183987:sns_no_reply_openbrainplatform_org", aws_sns_topic.nexus_alerts.arn]
  dimensions = {
    ServiceName = "blazegraph-obp-composite-4_ecs_service"
    ClusterName = "nexus_ecs_cluster"
  }
}

resource "aws_cloudwatch_metric_alarm" "blazegraph-search-out-of-memory-alarm" {
  alarm_name                = "blazegraph-search-out-of-memory-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = aws_cloudwatch_log_metric_filter.blazegraph-out-of-memory-error-metric.name
  namespace                 = "blazegraph"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 0
  alarm_description         = "OutOfMemoryErrors for Blazegraph Search"
  insufficient_data_actions = []
  alarm_actions             = ["arn:aws:sns:us-east-1:671250183987:sns_no_reply_openbrainplatform_org", aws_sns_topic.nexus_alerts.arn]
  dimensions = {
    ServiceName = "blazegraph-obp-composite-4_ecs_service"
    ClusterName = "nexus_ecs_cluster"
  }
}


resource "aws_cloudwatch_metric_alarm" "blazegraph-search-test-log-alarm" {
  alarm_name                = "blazegraph-search-test-log-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 1
  datapoints_to_alarm       = 1
  metric_name               = aws_cloudwatch_log_metric_filter.blazegraph-test-log-metric.name
  namespace                 = "blazegraph"
  period                    = 60
  statistic                 = "Sum"
  threshold                 = 0
  alarm_description         = "Test Log Alarm for Blazegraph Search"
  insufficient_data_actions = []
  alarm_actions             = ["arn:aws:sns:us-east-1:671250183987:sns_no_reply_openbrainplatform_org", aws_sns_topic.nexus_alerts.arn]
  dimensions = {
    ServiceName = "blazegraph-obp-composite-4_ecs_service"
    ClusterName = "nexus_ecs_cluster"
  }
}

