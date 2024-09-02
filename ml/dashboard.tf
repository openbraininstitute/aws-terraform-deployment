resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Machine-Learning"

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
              "AWS/EC2",
              "CPUUtilization",
              "ClusterName", module.ml_ecs_cluster,
              "ServiceName", module.ml_ecs_service_backend.name,
            ],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Backend CPU Utilization"
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
              "ClusterName", module.ml_ecs_cluster,
              "ServiceName", module.ml_ecs_service_backend.name,
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Backend Memory Utilization"
        }
      },
      {
        type   = "metric"
        x      = 16
        y      = 0
        width  = 8
        height = 4

        properties = {
          metrics = [
            ["AWS/ECS",
              "RequestCount",
              "ClusterName", module.ml_ecs_cluster,
              "ServiceName", module.ml_ecs_service_backend.name,
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Backend Request Count"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 4
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ES",
              "FreeStorageSpace",
              "ClusterName", module.ml_ecs_cluster,
              "ServiceName", aws_opensearch_domain.ml_opensearch.domain_name,
            ],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Opensearch Available Space"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 4
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "SearchableDocuments",
              "TargetGroup", module.ml_ecs_cluster,
              "LoadBalancer", aws_opensearch_domain.ml_opensearch.domain_name,
            ],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "OpenSearch Searchable Documents"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 10
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend,
              "LoadBalancer", join("/", slice(split("/", var.alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend,
              "LoadBalancer", join("/", slice(split("/", var.alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend,
              "LoadBalancer", join("/", slice(split("/", var.alb_listener_arn), 1, 4)),
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Public Load Balancer Target Count"
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
              "TargetGroup", aws_lb_target_group.ml_target_group_backend,
              "LoadBalancer", join("/", slice(split("/", var.alb_listener_arn), 1, 4)),
            ],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Public Load Balancer Response Time"
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 16
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_2XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_4XX_Count",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ]
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Private Load Balancer Target Count"
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 16
        width  = 12
        height = 6

        properties = {
          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "TargetGroup", aws_lb_target_group.ml_target_group_backend_private.arn,
              "LoadBalancer", join("/", slice(split("/", var.private_alb_listener_arn), 1, 4)),
            ],
          ]
          period = 300
          stat   = "Average"
          region = "us-east-1"
          title  = "Private Load Balancer Response Time"
        }
      },
    ]
  })
}