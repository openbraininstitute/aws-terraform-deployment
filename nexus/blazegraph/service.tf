locals {
  blazegraph_app_log_group_name = "${var.blazegraph_instance_name}_app"
}

resource "aws_ecs_service" "blazegraph_ecs_service" {
  name        = "${var.blazegraph_instance_name}_ecs_service"
  cluster     = var.ecs_cluster_arn
  launch_type = "FARGATE"

  task_definition = aws_ecs_task_definition.blazegraph_ecs_definition.arn
  desired_count   = 1

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  service_connect_configuration {
    enabled   = true
    namespace = var.aws_service_discovery_http_namespace_arn
    service {
      discovery_name = var.blazegraph_instance_name
      port_name      = var.blazegraph_instance_name
      client_alias {
        dns_name = "${var.blazegraph_instance_name}-svc"
        port     = var.blazegraph_port
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
  ]

  # force redeployment on each tf apply
  force_new_deployment = true

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