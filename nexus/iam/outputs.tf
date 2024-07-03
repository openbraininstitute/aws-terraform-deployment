output "nexus_ecs_task_execution_role_arn" {
  value = aws_iam_role.nexus_ecs_task_execution.arn
}

output "dockerhub_credentials_arn" {
  value = aws_secretsmanager_secret.dockerhub_credentials.arn
}