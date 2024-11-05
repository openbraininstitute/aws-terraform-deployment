locals {
  stats = [
    "p25",
    "p50",
    "p75",
    "p90",
    "p99",
    "Average",
    "Maximum",
  ]
}

resource "aws_cloudwatch_dashboard" "private_load_balancer_response_time" {
  dashboard_name = "PrivateLoadBalancerResponseTimes"

  dashboard_body = jsonencode({
    widgets = [
      for name, tg in var.private_load_balancer_target_suffixes : {
        type  = "metric"
        width = 12

        properties = {
          "title" : name,
          "metrics" = [for stat in local.stats : ["AWS/ApplicationELB", "TargetResponseTime", "TargetGroup", tg, "LoadBalancer", local.private_load_balancer_suffix, { "region" : var.aws_region, "stat" : stat }]],
          "view" : "timeSeries",
          "stacked" : false,
          "region" : var.aws_region,
          "stat" : "Sum",
          "period" : 300
          "yAxis" : { "left" : { "min" : 0 } }
        }
      }
    ]
  })
}

