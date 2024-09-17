resource "aws_cloudwatch_dashboard" "scholarag" {
  dashboard_name = "scholarag"

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
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ml_ecs_service_backend.name,
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "CPU Utilization"
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
          title   = "Memory Utilization"
        }
      },
    ]
  })
}

resource "aws_cloudwatch_dashboard" "neuroagent" {
  dashboard_name = "neuroagent"

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
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ecs_service_agent.name,
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "CPU Utilization"
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
            ["AWS/ECS",
              "MemoryUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ecs_service_agent.name,
            ]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "Memory Utilization"
        }
      },
    ]
  })
}
