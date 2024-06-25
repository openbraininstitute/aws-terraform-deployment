resource "aws_ecs_service" "nexus_fusion_ecs_service" {
  name            = "nexus_fusion_ecs_service"
  cluster         = var.ecs_cluster_arn
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_fusion_ecs_definition.arn
  desired_count   = 1

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = var.aws_lb_target_group_nexus_fusion_arn
    container_name   = "nexus_fusion"
    container_port   = 8000
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.aws_service_discovery_http_namespace_arn
    service {
      discovery_name = "fusion"
      port_name      = "fusion"
      client_alias {
        dns_name = "fusion-svc"
        port     = 8000
      }
    }
  }

  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [aws_cloudwatch_log_group.nexus_fusion]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus_fusion"
  }
  propagate_tags = "SERVICE"
}
