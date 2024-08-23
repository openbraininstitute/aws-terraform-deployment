locals {
  HTTPMetrics = [
    "HTTPCode_Target_2XX_Count",
    "HTTPCode_Target_4XX_Count",
    "HTTPCode_Target_5XX_Count",
  ]

  load_balancer_suffix = join("/", slice(split("/", var.load_balancer_id), 1, 4))
}

resource "aws_cloudwatch_dashboard" "load_balancer_http_status" {
  dashboard_name = "load_balancer_http_status"

  dashboard_body = jsonencode({
    widgets = [
      for name, tg in var.load_balancer_target_suffixes : {
        type  = "metric"
        width = 12

        properties = {
          "title" : name,
          "metrics" = [for metric in local.HTTPMetrics : ["AWS/ApplicationELB", metric, "TargetGroup", tg, "LoadBalancer", local.load_balancer_suffix, { "region" : var.aws_region }]],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.aws_region,
          "stat" : "Sum",
          "period" : 300
        }
      }
    ]
  })
}
