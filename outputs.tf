output "github_core_web_app_ecs_redeploy_role_arn" {
  value = var.is_staging ? module.github_core_webapp_ecs_redeploy_role[0].github_role_arn : null
}
