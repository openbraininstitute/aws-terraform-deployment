output "lb_rule_suffix" {
  description = "KG Inference Loadbalancer Rule Suffix"
  value       = aws_lb_target_group.kg_inference_api_tg.arn_suffix
}
