resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "scholarag"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 8
        height = 4

        properties = {
          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ml_ecs_service_backend.name,
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "Backend CPU Utilization"
        }
      },
      {
        type   = "metric"
        x      = 8
        y      = 0
        width  = 8
        height = 4

        properties = {
          metrics = [
            ["AWS/ECS",
              "MemoryUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ml_ecs_service_backend.name,
            ]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "Backend Memory Utilization"
        }
      },
    ]
  })
}
