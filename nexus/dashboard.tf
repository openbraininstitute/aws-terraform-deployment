locals {
  clustername            = "nexus_ecs_cluster"
  delta_servicename      = "delta_ecs_service"
  blazegraph_servicename = "blazegraph-main_ecs_service"
  fusion_servicename     = "fusion_ecs_service"
  nexus_bucket           = "nexus-bucket-production"
  DB_cluster             = "nexusobp"
}

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
            ["AWS/ECS", "CPUUtilization", "ServiceName", local.delta_servicename, "ClusterName", local.clustername, { region = var.aws_region }],
            ["AWS/ECS", "CPUUtilization", "ServiceName", "nexus-delta_ecs_service", "ClusterName", local.clustername, { region = var.aws_region }],
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
            ["AWS/ECS", "MemoryUtilization", "ServiceName", local.delta_servicename, "ClusterName", local.clustername, { region = var.aws_region }],
            ["AWS/ECS", "MemoryUtilization", "ServiceName", "nexus-delta_ecs_service", "ClusterName", local.clustername, { region = var.aws_region }],
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
            ["AWS/RDS", "CPUUtilization", "DBClusterIdentifier", local.DB_cluster, { "stat" : "Average", "region" : "us-east-1" }]
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
            ["AWS/RDS", "FreeableMemory", "DBClusterIdentifier", local.DB_cluster, { "stat" : "Average", "region" : "us-east-1" }]
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
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.clustername, "ServiceName", local.blazegraph_servicename, { "stat" : "Average", "region" : "us-east-1" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.clustername, "ServiceName", "blazegraph-composite_ecs_service", { "stat" : "Average", "region" : "us-east-1" }],
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.clustername, "ServiceName", "blazegraph_ecs_service", { "stat" : "Average", "region" : "us-east-1" }],
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
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.clustername, "ServiceName", local.blazegraph_servicename, { "stat" : "Average", "region" : "us-east-1" }],
            ["...", "blazegraph-composite_ecs_service", { "stat" : "Average", "region" : "us-east-1" }],
            ["...", "blazegraph_ecs_service", { "stat" : "Average", "region" : "us-east-1" }]
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
            ["AWS/S3", "BucketSizeBytes", "BucketName", local.nexus_bucket, "StorageType", "StandardStorage", { "stat" : "Average", "region" : "us-east-1" }]
          ]
          legend   = { position = "hidden" }
          region   = "us-east-1"
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
            ["AWS/S3", "BytesDownloaded", "BucketName", local.nexus_bucket, "FilterId", "EntireBucket", { region = var.aws_region }],
            ["AWS/S3", "BytesUploaded", "BucketName", local.nexus_bucket, "FilterId", "EntireBucket", { region = var.aws_region }],
          ]
          legend   = { position = "hidden" }
          region   = "us-east-1"
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
            ["AWS/ECS", "CPUUtilization", "ClusterName", local.clustername, "ServiceName", local.fusion_servicename, { "stat" : "Average", "region" : "us-east-1" }],
            ["...", "nexus_fusion_ecs_service", { "stat" : "Average", "region" : "us-east-1" }]
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
            ["AWS/ECS", "MemoryUtilization", "ClusterName", local.clustername, "ServiceName", local.fusion_servicename, { "stat" : "Average", "region" : "us-east-1" }],
            ["...", "nexus_fusion_ecs_service", { "stat" : "Average", "region" : "us-east-1" }]
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
