output "keycloak_lb_rule_suffix" {
  description = "KeyCloak Loadbalancer Rule Suffix"
  value       = module.keycloak.keycloak_lb_rule_suffix
}

output "private_keycloak_lb_rule_suffix" {
  description = "KeyCloak Private Loadbalancer Rule Suffix"
  value       = module.keycloak.private_keycloak_lb_rule_suffix
}
