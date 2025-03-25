output "github_core_web_app_main_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_main_ecs_redeploy_role[0].github_role_arn : null
}

output "github_core_web_app_next_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_next_ecs_redeploy_role[0].github_role_arn : null
}

output "nexus_es_main_http_endpoint" {
  value = module.nexus.nexus_es_main_http_endpoint
}

output "nexus_es_openscience_http_endpoint" {
  value = var.is_production ? module.nexus.nexus_es_openscience_http_endpoint : null
}
