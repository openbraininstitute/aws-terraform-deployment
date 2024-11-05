locals {
  clustername = "sbo-keycloak-cluster"
  servicename = "sbo-keycloak-service"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "Keycloak"

  dashboard_body = jsonencode({
    "widgets" : [
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              local.clustername,
              "ServiceName",
              local.servicename,
              { "stat" : "Average", "region" : var.aws_region },
            ]
          ],
          "legend" : { "position" : "hidden" },
          "region" : "${var.aws_region}",
          "liveData" : false,
          "timezone" : "UTC",
          "title" : "CPUUtilization: Average",
          "view" : "timeSeries",
          "stacked" : false,
          "period" : 300,
          "yAxis" : { "left" : { "min" : 0, "max" : 100, "label" : "" } },
        },
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 0,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              local.clustername,
              "ServiceName",
              local.servicename,
              { "stat" : "Average", "region" : var.aws_region },
            ]
          ],
          "legend" : { "position" : "hidden" },
          "region" : "${var.aws_region}",
          "liveData" : false,
          "timezone" : "UTC",
          "title" : "MemoryUtilization: Average",
          "view" : "timeSeries",
          "stacked" : false,
          "period" : 300,
        },
      },
      {
        "height" : 15,
        "width" : 24,
        "y" : 12,
        "x" : 0,
        "type" : "explorer",
        "properties" : {
          "metrics" : [
            {
              "metricName" : "CPUUtilization",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "ReadLatency",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "DatabaseConnections",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Sum",
            },
            {
              "metricName" : "FreeStorageSpace",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "FreeableMemory",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "ReadThroughput",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "ReadIOPS",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "WriteLatency",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "WriteThroughput",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
            {
              "metricName" : "WriteIOPS",
              "resourceType" : "AWS::RDS::DBInstance",
              "stat" : "Average",
            },
          ],
          "labels" : [{ "key" : "SBO_Billing", "value" : "keycloak" }],
          "widgetOptions" : {
            "legend" : { "position" : "bottom" },
            "view" : "timeSeries",
            "stacked" : false,
            "rowsPerPage" : 50,
            "widgetsPerRow" : 2,
          },
          "period" : 300,
          "splitBy" : "",
          "region" : "${var.aws_region}",
          "title" : "RDS",
        },
      },
      {
        "height" : 15,
        "width" : 24,
        "y" : 27,
        "x" : 0,
        "type" : "explorer",
        "properties" : {
          "metrics" : [
            {
              "metricName" : "ClientConnections",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Sum",
            },
            {
              "metricName" : "DataReadIOBytes",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Average",
            },
            {
              "metricName" : "DataWriteIOBytes",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Average",
            },
            {
              "metricName" : "BurstCreditBalance",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Average",
            },
            {
              "metricName" : "PercentIOLimit",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Average",
            },
            {
              "metricName" : "PermittedThroughput",
              "resourceType" : "AWS::EFS::FileSystem",
              "stat" : "Average",
            },
          ],
          "labels" : [{ "key" : "SBO_Billing", "value" : "keycloak" }],
          "widgetOptions" : {
            "legend" : { "position" : "bottom" },
            "view" : "timeSeries",
            "stacked" : false,
            "rowsPerPage" : 50,
            "widgetsPerRow" : 2,
          },
          "period" : 300,
          "splitBy" : "",
          "region" : "${var.aws_region}",
          "title" : "EFS",
        },
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 6,
        "x" : 0,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "TargetGroup",
              aws_lb_target_group.private_keycloak_target_group.arn_suffix,
              "LoadBalancer",
              join(
                "/",
                slice(split("/", var.private_alb_https_listener_arn), 1, 4),
              ),
              "AvailabilityZone",
              "${var.aws_region}b",
              { "region" : "${var.aws_region}", "id" : "m5" },
            ]
          ],
          "legend" : { "position" : "hidden" },
          "title" : "RequestCount: Sum",
          "region" : "${var.aws_region}",
          "liveData" : false,
          "view" : "timeSeries",
          "stacked" : false,
          "stat" : "Sum",
          "period" : 300,
          "yAxis" : { "left" : { "min" : 0 } },
        },
      },
      {
        "height" : 6,
        "width" : 6,
        "y" : 6,
        "x" : 6,
        "type" : "metric",
        "properties" : {
          "metrics" : [
            [
              "AWS/ApplicationELB",
              "HTTPCode_Target_5XX_Count",
              "TargetGroup",
              aws_lb_target_group.private_keycloak_target_group.arn_suffix,
              "LoadBalancer",
              join(
                "/",
                slice(split("/", var.private_alb_https_listener_arn), 1, 4),
              ),
              "AvailabilityZone",
              "${var.aws_region}b",
              {
                "region" : "${var.aws_region}",
                "id" : "m1",
                "label" : "5XX",
                "color" : "#d62728",
              },
            ],
            [
              ".",
              "HTTPCode_Target_4XX_Count",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              { "region" : "${var.aws_region}", "id" : "m2", "label" : "4XX" },
            ],
            [
              ".",
              "HTTPCode_Target_3XX_Count",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              {
                "region" : "${var.aws_region}",
                "id" : "m3",
                "label" : "3XX",
                "color" : "#17becf",
              },
            ],
            [
              ".",
              "HTTPCode_Target_2XX_Count",
              ".",
              ".",
              ".",
              ".",
              ".",
              ".",
              {
                "region" : "${var.aws_region}",
                "id" : "m4",
                "label" : "2XX",
                "color" : "#2ca02c",
              },
            ],
          ],
          "legend" : { "position" : "bottom" },
          "title" : "HTTPCodes_Target_Count: Sum",
          "region" : "${var.aws_region}",
          "liveData" : false,
          "view" : "timeSeries",
          "stacked" : false,
          "stat" : "Sum",
          "period" : 300,
          "yAxis" : { "left" : { "min" : 0 } },
        },
      },
    ]
  })
}
