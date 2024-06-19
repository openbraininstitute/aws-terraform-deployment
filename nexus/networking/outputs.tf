output "subnet_id" {
  value = aws_subnet.nexus_main.id
}

output "subnet_b_id" {
  value = aws_subnet.nexus_b.id
}

output "main_subnet_sg_id" {
  value = aws_security_group.main_sg.id
}

output "psql_subnets_ids" {
  value = aws_network_acl.nexus_db.subnet_ids
}

output "elastic_vpc_endpoint_id" {
  value = aws_vpc_endpoint.nexus_es_vpc_ep.id
}

output "elastic_hosted_zone_name" {
  value = aws_route53_zone.nexus_es_zone.name
}