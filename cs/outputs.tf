output "private_keycloak_lb_rule_suffix" {
  description = "KeyCloak Private Loadbalancer Rule Suffix"
  value       = module.keycloak.private_keycloak_lb_rule_suffix
}

output "keycloak_ecs_cluster_name" {
  value = module.keycloak.ecs_cluster_name
}

output "keycloak_ecs_service_name" {
  value = module.keycloak.ecs_service_name
}

output "keycloak_ecs_task_definition_name" {
  value = module.keycloak.ecs_task_definition_name
}

output "jupyterhub_homedirs_efs_security_group_id" {
  value = module.jupyterhub_eks.jupyterhub_homedirs_efs_security_group_id
}

output "jupyterhub_homedirs_efs_file_system_id" {
  value = module.jupyterhub_eks.jupyterhub_homedirs_efs_file_system_id
}

output "jupyterhub_eks_public_a_cidr" {
  value = module.jupyterhub_eks.jupyterhub_eks_public_a_cidr
}

output "jupyterhub_eks_public_b_cidr" {
  value = module.jupyterhub_eks.jupyterhub_eks_public_b_cidr
}

output "jupyterhub_eks_private_a_cidr" {
  value = module.jupyterhub_eks.jupyterhub_eks_private_a_cidr
}

output "jupyterhub_eks_private_b_cidr" {
  value = module.jupyterhub_eks.jupyterhub_eks_private_b_cidr
}

output "keycloak_rds_db_identifier" {
  value = module.keycloak.rds_db_identifier
}