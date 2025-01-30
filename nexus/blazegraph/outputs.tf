output "efs_blazegraph_dns_name" {
  value = module.storage.aws_efs_mount_target_efs_for_blazegraph_dns_name
}

locals {
  blazegraph_dns_name = length(module.ecs) > 0 ? module.ecs[0].blazegraph_dns_name : null
}

output "http_endpoint" {
  value = "http://${local.blazegraph_dns_name}:${var.blazegraph_port}/blazegraph"
}

output "service_name" {
  value = length(module.ecs) > 0 ? module.ecs[0].blazegraph_ecs_service_name : null
}

output "log_group" {
  value = length(module.ecs) > 0 ? module.ecs[0].blazegraph_app_log_group_name : null
}
