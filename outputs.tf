output "github_core_web_app_main_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_main_ecs_redeploy_role[0].github_role_arn : null
}

output "github_core_web_app_next_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_next_ecs_redeploy_role[0].github_role_arn : null
}

output "notebook_service" {
  value = module.notebook_service
}

output "notebook_service_redeploy_role" {
  value = var.is_staging ? module.github_notebook_service_ecs_redeploy_role[0] : null
}

output "apigw_arn" {
  value = module.hpc.apigw_arn
}
