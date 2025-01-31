output "service_name" {
  value = length(module.ecs) > 0 ? module.ecs[0].nexus_fusion_ecs_service_name : ""
}

