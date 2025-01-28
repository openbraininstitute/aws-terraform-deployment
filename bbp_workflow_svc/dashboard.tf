resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "bbp-workflow"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["ECS/ContainerInsights", "CpuUtilized", "ClusterName", aws_ecs_cluster.this.name],
            [".", "TaskCount", ".", "."],
            [".", "MemoryUtilized", ".", "."],
            [".", "NetworkRxBytes", ".", "."],
            [".", "NetworkTxBytes", ".", "."],
          ],
          "period" : 300,
          "region" : var.aws_region,
          "stacked" : false,
          "title" : "Instance count",
          "view" : "timeSeries",
        }
      },
      {
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/ApiGateway", "4xx", "Stage", "$default", "ApiId", aws_apigatewayv2_api.this.id],
            [".", "5xx", ".", ".", ".", "."],
          ],
          "period" : 300,
          "region" : var.aws_region,
          "stacked" : false,
          "title" : "API Errors",
          "view" : "timeSeries",
        }
      },
      {
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/ApiGateway", "Count", "Stage", "$default", "ApiId", aws_apigatewayv2_api.this.id],
          ],
          "period" : 300,
          "region" : var.aws_region,
          "stacked" : false,
          "title" : "Request count",
          "view" : "timeSeries",
        }
      },
      {
        "type" : "metric",
        "properties" : {
          "metrics" : [
            ["AWS/ApiGateway", "DataProcessed", "Stage", "$default", "ApiId", aws_apigatewayv2_api.this.id],
            [".", "Latency", ".", ".", ".", "."],
          ],
          "period" : 300,
          "region" : var.aws_region,
          "stacked" : false,
          "title" : "Data",
          "view" : "timeSeries",
        }
      },
    ]
  })
}
