output "lb_rule_suffix" {
  description = "BlueNaaS service Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.bluenaas.arn_suffix
}
