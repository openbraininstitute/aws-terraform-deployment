output "efs_blazegraph_dns_name" {
  value = aws_efs_mount_target.efs_for_blazegraph.dns_name
}

output "blazebraph_dns_name" {
  value = aws_ecs_service.blazegraph_ecs_service.service_connect_configuration[0].service[0].client_alias[0].dns_name
}