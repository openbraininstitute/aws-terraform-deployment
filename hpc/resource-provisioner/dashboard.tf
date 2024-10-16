resource "aws_cloudwatch_dashboard" "resource_provisioner_dashboard" {
  dashboard_name = "HPC-Resource-Provisioner"
  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/Lambda", "Invocations", "FunctionName", "hpc-resource-provisioner", { "region" : "${var.aws_region}" }],
            [".", "Errors", ".", ".", { "region" : "${var.aws_region}" }],
            [".", "ConcurrentExecutions", ".", ".", { "region" : "${var.aws_region}" }],
            [".", "Invocations", ".", "hpc-resource-provisioner-creator", "Resource", "hpc-resource-provisioner-creator"],
            [".", "ConcurrentExecutions", ".", ".", ".", "."],
            [".", "Errors", ".", ".", ".", "."]
          ],
          "region" : "${var.aws_region}",
          "start" : "-PT3H",
          "period" : 300,
          "end" : "P0D"
        }
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "view" : "timeSeries",
          "stacked" : false,
          "metrics" : [
            ["AWS/Lambda", "Duration", "FunctionName", "hpc-resource-provisioner", { "region" : "${var.aws_region}" }],
            ["...", "hpc-resource-provisioner-creator"]
          ],
          "region" : "${var.aws_region}",
          "period" : 300
        }
      },
      {
        "height" : 6,
        "width" : 24,
        "y" : 6,
        "x" : 0,
        "type" : "log",
        "properties" : {
          "query" : "SOURCE '/aws/lambda/hpc-resource-provisioner' | SOURCE '/aws/lambda/hpc-resource-provisioner-creator' | filter @type = \"REPORT\"\n    | stats max(@memorySize / 1000 / 1000) as provisonedMemoryMB,\n        min(@maxMemoryUsed / 1000 / 1000) as smallestMemoryRequestMB,\n        avg(@maxMemoryUsed / 1000 / 1000) as avgMemoryUsedMB,\n        max(@maxMemoryUsed / 1000 / 1000) as maxMemoryUsedMB,\n        provisonedMemoryMB - maxMemoryUsedMB as overProvisionedMB\n    ",
          "region" : "${var.aws_region}",
          "title" : "HPC Resource Provisioner Memory Stats",
          "view" : "table"
        }
      }
    ]
    }
  )
}
