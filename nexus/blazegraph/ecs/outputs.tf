output "blazegraph_dns_name" {
  value = aws_ecs_service.blazegraph_ecs_service.service_connect_configuration[0].service[0].client_alias[0].dns_name
}

output "blazegraph_ecs_service_name" {
  value = aws_ecs_service.blazegraph_ecs_service.name
}

output "blazegraph_app_log_group_name" {
  value = local.blazegraph_app_log_group_name
}
