output "vpc_peering_security_group_id" {
  value = module.security.vpc_peering_security_group_id
}

output "pcluster_vpc_default_sg_id" {
  value = module.vpc.pcluster_vpc_default_sg_id
}

output "resource_provisioner_api_url" {
  description = "The URL of the resource provisioner API"
  value       = module.resource-provisioner.api_url
}
