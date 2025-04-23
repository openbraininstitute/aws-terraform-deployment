output "private_lb_rule_suffix" {
  description = "obi-generative-gui Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.obi_generative_gui_private_tg.arn_suffix
}
