output "private_keycloak_lb_rule_suffix" {
  description = "KeyCloak Private Loadbalancer Rule Suffix"
  value       = module.keycloak.private_keycloak_lb_rule_suffix
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
