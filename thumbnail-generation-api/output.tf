output "lb_rule_suffix" {
  description = "Thumbnail Generator Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.thumbnail_generation_api_tg.arn_suffix
}
