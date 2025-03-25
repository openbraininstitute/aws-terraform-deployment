output "private_fusion_lb_rule_suffix" {
  value = module.obp_fusion_target_group.private_lb_rule_suffix
}

output "private_delta_lb_rule_suffix" {
  value = module.obp_delta_target_group.private_lb_rule_suffix
}

output "nexus_domain_name" {
  value = var.domain_name
}

output "nexus_es_main_http_endpoint" {
  value = module.elasticsearch_obp.http_endpoint_ec2
}

output "nexus_es_openscience_http_endpoint" {
  value = var.is_production ? module.elasticsearch_openscience[0].http_endpoint_ec2 : null
}
