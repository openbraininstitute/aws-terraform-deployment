output "private_keycloak_lb_rule_suffix" {
  description = "Keycloak Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.private_keycloak_target_group.arn_suffix
}
