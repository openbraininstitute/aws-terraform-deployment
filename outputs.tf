output "notebook_service" {
  value = module.notebook_service
}

output "notebook_service_redeploy_role" {
  value = var.is_staging ? module.github_notebook_service_ecs_redeploy_role[0] : null
}

output "keycloak_redeploy_role" {
  value = var.is_staging ? module.github_keycloak_ecs_redeploy_role[0] : null
}

output "github_core_web_app_preview_deploy_role_arn" {
  value = var.is_staging ? module.core_webapp_preview[0].github_deploy_role_arn : null

}
