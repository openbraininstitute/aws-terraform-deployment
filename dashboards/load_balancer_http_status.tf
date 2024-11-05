locals {
  HTTPMetrics = [
    "HTTPCode_Target_2XX_Count",
    "HTTPCode_Target_4XX_Count",
    "HTTPCode_Target_5XX_Count",
  ]
}

resource "aws_cloudwatch_dashboard" "private_load_balancer_http_status" {
  dashboard_name = "private_load_balancer_http_status"

  dashboard_body = jsonencode({
    widgets = [
      for name, tg in var.private_load_balancer_target_suffixes : {
        type  = "metric"
        width = 12

        properties = {
          "title" : name,
          "metrics" = [for metric in local.HTTPMetrics : ["AWS/ApplicationELB", metric, "TargetGroup", tg, "LoadBalancer", local.private_load_balancer_suffix, { "region" : var.aws_region }]],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.aws_region,
          "stat" : "Sum",
          "period" : 300
          "yAxis" : { "left" : { "min" : 0 }
          }
        }
      }
    ]
  })
}
