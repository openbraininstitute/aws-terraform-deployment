output "pcluster_vpc_id" {
  value = aws_vpc.pcluster_vpc.id
}

output "pcluster_vpc_default_sg_id" {
  value = aws_vpc.pcluster_vpc.default_security_group_id
}

output "peering_connection_id" {
  value = aws_vpc_peering_connection.test_to_pcluster.id
}
