output "private_fusion_lb_rule_suffix" {
  value = module.obp_fusion_target_group.private_lb_rule_suffix
}

output "private_delta_lb_rule_suffix" {
  value = module.obp_delta_target_group.private_lb_rule_suffix
}
