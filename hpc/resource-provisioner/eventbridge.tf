# EventBridge, aka The Service Formerly Known As CloudWatch Events - hence the names of the resources

resource "aws_cloudwatch_event_rule" "dra_event" {
  count       = var.suffix == "dev" ? 1 : 0
  name        = "dra-event"
  description = "Whenever a DRA is ready, trigger resource provisioner"
  event_pattern = jsonencode(
    {
      source      = ["aws.fsx"],
      detail-type = ["AWS API Call via CloudTrail"],
      detail = {
        "eventSource" = ["fsx.amazonaws.com"]
        # "eventName"   = ["CreateDataRepositoryAssociation"]
      }
    }
  )
}

resource "aws_cloudwatch_event_target" "resource_provisioner_dra" {
  count = var.suffix == "dev" ? 1 : 0
  arn   = "${aws_api_gateway_stage.hpc_resource_provisioner_api_stage.execution_arn}/POST/hpc-provisioner/dra"
  rule  = aws_cloudwatch_event_rule.dra_event[0].id

  http_target {
    query_string_parameters = {
      Body = "$.detail.body"
    }
  }
}
