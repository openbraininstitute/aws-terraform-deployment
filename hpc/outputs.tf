output "vpc_peering_security_group_id" {
  value = module.security.vpc_peering_security_group_id
}

output "resource_provisioner_api_url" {
  description = "The URL of the resource provisioner API"
  value = module.resource-provisioner.api_url
}
