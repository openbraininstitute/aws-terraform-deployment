output "lb_rule_suffix" {
  description = "BlueNaaS service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.bluenaas.arn_suffix
}

output "private_lb_rule_suffix" {
  description = "BlueNaaS service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.bluenaas_private_tg.arn_suffix
}
