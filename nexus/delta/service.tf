resource "aws_ecs_service" "nexus_app_ecs_service" {
  count = var.nexus_app_ecs_number_of_containers > 0 ? 1 : 0

  name            = "nexus_app_ecs_service"
  cluster         = var.ecs_cluster_arn
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.nexus_app_ecs_definition[0].arn
  desired_count   = 1
  #iam_role        = "${var.ecs_iam_role_name}"

  # ensure that there are not multiple tasks running at the same time during deployment
  deployment_maximum_percent         = 100
  deployment_minimum_healthy_percent = 0

  load_balancer {
    target_group_arn = var.aws_lb_target_group_nexus_app_arn
    container_name   = "nexus_app"
    container_port   = 8080
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.aws_service_discovery_http_namespace_arn
  }

  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_app,
    aws_iam_role.ecs_nexus_app_task_execution_role, # wrong?
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = {
    SBO_Billing = "nexus_app"
  }
}