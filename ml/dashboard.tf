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
              { "stat" : "Average" }
            ],
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ml_ecs_service_backend.name,
              { "stat" : "Maximum" }
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
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
              { "stat" : "Average" },
            ],
            ["AWS/ECS",
              "MemoryUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ml_ecs_service_backend.name,
              { "stat" : "Maximum" }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          region  = var.aws_region
          title   = "Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ES",
              "SearchLatency",
              "DomainName", var.os_domain_name,
              "ClientId", var.account_id
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "Search Latency (Opensearch)"
        }


      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          metrics = [
            [
              "AWS/ES",
              "CPUUtilization",
              "DomainName", var.os_domain_name,
              "ClientId", var.account_id,
              { "stat" : "Average" }
            ],
            [
              "AWS/ES",
              "CPUUtilization",
              "DomainName", var.os_domain_name,
              "ClientId", var.account_id,
              { "stat" : "Maximum" }
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          region  = var.aws_region
          title   = "CPU Utilization (Opensearch)"
        }


      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Generic Private Load Balancer Target Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 10
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Generic Private Load Balancer Response Time"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Private Load Balancer Target Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 10
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Private Load Balancer Response Time"
        }
      },
    ]
    }
  )
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
              { "stat" : "Average" }
            ],
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ecs_service_agent.name,
              { "stat" : "Maximum" }
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
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
              { "stat" : "Average" },
            ],
            ["AWS/ECS",
              "MemoryUtilization",
              "ClusterName", module.ml_ecs_cluster.name,
              "ServiceName", module.ecs_service_agent.name,
              { "stat" : "Maximum" }
            ]
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          region  = var.aws_region
          title   = "Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier", module.ml_rds_postgres.db_instance_identifier,
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          stat    = "Average"
          region  = var.aws_region
          title   = "Free Storage Space (RDS)"
        }


      },
      {
        type   = "metric"
        x      = 8
        y      = 6
        width  = 8
        height = 6
        properties = {
          "metrics" = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier", module.ml_rds_postgres.db_instance_identifier,
              { "stat" : "Average" }
            ],
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier", module.ml_rds_postgres.db_instance_identifier,
              { "stat" : "Maximum" }
            ],
          ]
          view    = "timeSeries"
          stacked = false
          period  = 300
          region  = var.aws_region
          title   = "CPU Utilization (RDS)"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 6
        width  = 8
        height = 6
        properties = {
          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier", module.ml_rds_postgres.db_instance_identifier,
            ],
          ]
          view    = "timeSeries"
          stacked = false
          stat    = "Average"
          period  = 300
          region  = var.aws_region
          title   = "Database Connections (RDS)"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "TargetGroup", aws_lb_target_group.generic_private_ml_target_group_agent.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.generic_private_ml_target_group_agent.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "TargetGroup", aws_lb_target_group.generic_private_ml_target_group_agent.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ]
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Generic Private Load Balancer Target Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 10
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "TargetGroup", aws_lb_target_group.generic_private_ml_target_group_agent.arn_suffix,
              "LoadBalancer", join("/", slice(split("/", var.generic_private_alb_listener_arn), 1, 4)),
            ],
          ]
          period = 300
          stat   = "Average"
          region = var.aws_region
          title  = "Generic Private Load Balancer Response Time"
        }
      },
    ]
    }
  )
}

