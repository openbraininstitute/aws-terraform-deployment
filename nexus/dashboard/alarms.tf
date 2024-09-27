resource "aws_cloudwatch_metric_alarm" "blazegraph-search-cpu-alarm" {
  alarm_name                = "blazegraph-search-cpu-alarm"
  comparison_operator       = "GreaterThanThreshold"
  evaluation_periods        = 2
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/ECS"
  period                    = 60
  statistic                 = "Average"
  threshold                 = 90
  alarm_description         = "CPU utilization for Blazegraph Search"
  insufficient_data_actions = []
  alarm_actions             = ["arn:aws:sns:us-east-1:671250183987:sns_no_reply_openbrainplatform_org"]
  dimensions = {
    ServiceName = "blazegraph-obp-composite-4_ecs_service"
    ClusterName = "nexus_ecs_cluster"
  }
}
