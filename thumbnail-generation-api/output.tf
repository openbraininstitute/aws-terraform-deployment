output "private_lb_rule_suffix" {
  description = "Thumbnail Generator Private Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.thumbnail_generation_api_private_tg.arn_suffix
}
