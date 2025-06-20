locals {
  clustername  = "small-scale-simulator"
  servicenames = ["redis", "api", "worker"]
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Small_scale_simulator"

  dashboard_body = jsonencode({
    widgets = flatten([
      for i, service in local.servicenames : [
        {
          type   = "metric"
          x      = 0
          y      = i * 6
          width  = 12
          height = 6

          properties = {
            metrics = [
              ["AWS/ECS",
                "CPUUtilization",
                "ClusterName", local.clustername,
                "ServiceName", service,
                { "stat" : "Average",
              "region" : var.aws_region }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = var.aws_region
            title   = "${upper(service)} CPUUtilization: Average"
            period  = 300
          }
        },
        {
          type   = "metric"
          x      = 12
          y      = i * 6
          width  = 12
          height = 6

          properties = {
            metrics = [
              ["AWS/ECS",
                "MemoryUtilization",
                "ClusterName", local.clustername,
                "ServiceName", service,
              { "stat" : "Average", "region" : var.aws_region }]
            ]
            view    = "timeSeries"
            stacked = false
            region  = var.aws_region
            title   = "${upper(service)} MemoryUtilization: Average"
            period  = 300
          }
        }
      ]
    ])
  })
}
