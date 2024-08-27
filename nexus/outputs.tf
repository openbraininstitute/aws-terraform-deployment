output "fusion_lb_rule_suffix" {
  value = module.obp_fusion_target_group.lb_rule_suffix
}

output "delta_lb_rule_suffix" {
  value = module.obp_delta_target_group.lb_rule_suffix
}
