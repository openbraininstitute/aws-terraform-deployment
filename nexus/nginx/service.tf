resource "aws_ecs_service" "delta_nginx_ecs_service" {
  name            = "${local.instance_name}_ecs_service"
  cluster         = var.ecs_cluster_arn
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.delta_nginx_ecs_definition.arn
  desired_count   = var.desired_count

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = var.delta_nginx_target_group_arn
    container_name   = local.instance_name
    container_port   = 80
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.aws_service_discovery_http_namespace_arn
    service {
      discovery_name = local.instance_name
      port_name      = local.instance_name
      client_alias {
        dns_name = "${local.instance_name}-svc"
        port     = 80
      }
    }
  }

  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_app
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  propagate_tags = "SERVICE"
}