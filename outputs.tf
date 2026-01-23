output "github_core_web_app_dev_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_dev_ecs_redeploy_role[0].github_role_arn : null
}


output "notebook_service" {
  value = module.notebook_service
}

output "notebook_service_redeploy_role" {
  value = var.is_staging ? module.github_notebook_service_ecs_redeploy_role[0] : null
}
