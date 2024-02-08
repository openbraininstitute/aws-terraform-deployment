resource "aws_ecs_service" "nexus_storage_ecs_service" {
  name            = "nexus_storage_ecs_service"
  cluster         = var.ecs_cluster_arn
  launch_type     = "EC2"
  task_definition = aws_ecs_task_definition.nexus_storage_ecs_definition.arn
  desired_count   = var.nexus_storage_ecs_number_of_containers

  # TODO add a load balancer to get a static host
  # load_balancer {
  #   target_group_arn = aws_lb_target_group.nexus_storage.arn
  #   container_name   = "nexus_storage"
  #   container_port   = 8081
  # }

  enable_execute_command = true

  network_configuration {
    security_groups  = [var.subnet_security_group_id]
    subnets          = [var.subnet_id]
    assign_public_ip = false
  }
  depends_on = [
    aws_cloudwatch_log_group.nexus_storage,
    aws_iam_role.ecs_nexus_storage_task_execution_role,
  ]
  # force redeployment on each tf apply
  force_new_deployment = true
  lifecycle {
    ignore_changes = [desired_count]
  }
  tags = { SBO_Billing = "nexus_storage" }
}
