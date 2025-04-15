locals {
  clustername = "obi_generative_gui_ecs_cluster"
  servicename = "obi_generative_gui_ecs_service"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "obi-generative-gui"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", local.clustername,
              "ServiceName", local.servicename,
              {
                "stat" : "Average",
                "region" : var.aws_region
              }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "CPUUtilization: Average"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName", local.clustername,
              "ServiceName", local.servicename,
              { "stat" : "Average", "region" : var.aws_region }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MemoryUtilization: Average"
          period  = 300
        }
      }
    ]
  })
}
