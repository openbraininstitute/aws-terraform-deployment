resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Nexus"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.delta_service_name, "ClusterName", var.cluster_name, { region = var.aws_region }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", var.delta_service_name, "ClusterName", var.cluster_name, { region = var.aws_region }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "Delta CPU"
          period  = 300
          yAxis   = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 0
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ServiceName", var.delta_service_name, "ClusterName", var.cluster_name, { region = var.aws_region }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", var.delta_service_name, "ClusterName", var.cluster_name, { region = var.aws_region }],
          ]
          view    = "timeSeries"
          stacked = false
          region  = var.aws_region
          title   = "MemoryUtilization: Average"
          period  = 300
          yAxis   = { left = { min = 0 } }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 5
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", var.database, { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "hidden" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "Postgres CPU"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 5
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/RDS", "FreeableMemory", "DBClusterIdentifier", var.database, { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "hidden" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "Postgres Freeable Memory"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0 } }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 10
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.blazegraph_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.blazegraph_composite_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.blazegraph_service_name, { "stat" : "Average", "region" : var.aws_region }],
          ]
          legend   = { position = "bottom" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "BlazeGraph CPU"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 10
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.blazegraph_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["...", var.blazegraph_composite_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["...", var.blazegraph_service_name, { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "bottom" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "BlazeGraph Memory"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 15
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/S3", "BucketSizeBytes", "BucketName", var.s3_bucket, "StorageType", "StandardStorage", { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "hidden" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          start    = "-PT168H"
          title    = "S3 Bucket Size"
          view     = "timeSeries"
          stacked  = false
          period   = 3600
          end      = "P0D"
          yAxis    = { left = { min = 0 } }
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 15
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/S3", "BytesDownloaded", "BucketName", var.s3_bucket, "FilterId", "EntireBucket", { region = var.aws_region }],
            ["AWS/S3", "BytesUploaded", "BucketName", var.s3_bucket, "FilterId", "EntireBucket", { region = var.aws_region }],
          ]
          legend   = { position = "hidden" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "S3 Bytes Transferred"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          stat     = "Sum"
          yAxis    = { left = { min = 0 } }
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 20
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", var.cluster_name, "ServiceName", var.fusion_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["...", var.fusion_service_name, { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "bottom" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "Fusion CPU"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0, max = 100 } }
        }
      },
      {
        type   = "metric"
        x      = 10
        y      = 20
        width  = 10
        height = 5

        properties = {
          metrics = [
            ["AWS/ECS", "MemoryUtilization", "ClusterName", var.cluster_name, "ServiceName", var.fusion_service_name, { "stat" : "Average", "region" : var.aws_region }],
            ["...", var.fusion_service_name, { "stat" : "Average", "region" : var.aws_region }]
          ]
          legend   = { position = "bottom" }
          region   = var.aws_region
          liveData = false
          timezone = "UTC"
          title    = "Fusion Memory"
          view     = "timeSeries"
          stacked  = false
          period   = 300
          yAxis    = { left = { min = 0, max = 100 } }
        }
      }

    ]
  })
}
