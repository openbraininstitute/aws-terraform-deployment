output "efs_blazegraph_dns_name" {
  value = aws_efs_mount_target.efs_for_blazegraph.dns_name
}

locals {
  blazegraph_dns_name = aws_ecs_service.blazegraph_ecs_service.service_connect_configuration[0].service[0].client_alias[0].dns_name
}

output "http_endpoint" {
  value = "http://${local.blazegraph_dns_name}:${var.blazegraph_port}/blazegraph"
}