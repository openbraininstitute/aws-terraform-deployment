resource "aws_ecs_service" "blazegraph_ecs_service" {
  name        = "${var.blazegraph_instance_name}_ecs_service"
  cluster     = var.ecs_cluster_arn
  launch_type = "FARGATE"

  enable_execute_command = true

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
    var.blazegraph_log_group_name
  ]

  # force redeployment on each tf apply
  force_new_deployment = true

  lifecycle {
    ignore_changes = [desired_count]
  }
  propagate_tags = "SERVICE"
}

