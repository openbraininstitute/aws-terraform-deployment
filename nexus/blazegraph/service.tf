locals {
  blazegraph_app_log_group_name = "blazegraph_app"
}

resource "aws_ecs_service" "blazegraph_ecs_service" {
  count = var.blazegraph_ecs_number_of_containers > 0 ? 1 : 0

  name        = "blazegraph_ecs_service"
  cluster     = var.ecs_cluster_arn
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.blazegraph_ecs_definition[0].arn
  desired_count   = var.blazegraph_ecs_number_of_containers
  #iam_role        = "${var.ecs_iam_role_name}"

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  service_connect_configuration {
    enabled   = true
    namespace = var.aws_service_discovery_http_namespace_arn
    service {
      discovery_name = "blazegraph"
      port_name      = "blazegraph"
      client_alias {
        dns_name = "blazegraph-svc"
        port     = 9999
      }
    }
  }

  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.blazegraph_app
    #aws_iam_role.ecs_blazegraph_task_execution_role, # wrong?

  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  #triggers = {
  #  redeployment = timestamp()
  #}
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus"
  }
}

resource "aws_cloudwatch_log_group" "blazegraph_app" {
  name              = local.blazegraph_app_log_group_name
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "blazegraph"
    SBO_Billing = "nexus"
  }
}