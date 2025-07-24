output "ecs_cluster_name" {
  value = aws_ecs_cluster.core_webapp.name
}

output "ecs_service_name" {
  value = aws_ecs_service.core_webapp_ecs_service[0].name
}

output "ecs_task_definition_name" {
  value = aws_ecs_task_definition.core_webapp_ecs_definition[0].family
}

output "private_lb_rule_suffix" {
  description = "Core Web app Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.core_webapp_private.arn_suffix
}

output "cloudfront_distribution_id" {
  description = "ID of the CloudFront distribution"
  value       = aws_cloudfront_distribution.core_webapp_cdn.id
}
