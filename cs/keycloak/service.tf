resource "aws_ecs_service" "keycloak_service_terraform" {
  name            = "sbo-keycloak-service"
  cluster         = aws_ecs_cluster.sbo-keycloak-cluster.id  # the ECS cluster ID where we run the service
  task_definition = aws_ecs_task_definition.sbo_keycloak_task.arn  # the ARN of the task definition
  desired_count   = 1
  launch_type = "FARGATE"
  network_configuration {
   subnets         = var.private_subnets
   security_groups = var.security_groups
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.keycloak_target_group.arn
    container_name = "keycloak-container"
    container_port = 8081
  }
  depends_on = [aws_lb_listener.keycloak]
}

