# we are decomm Nexus, this code will be deleted soon
output "writer_endpoint" {
  value = var.is_nexus_obp_running ? aws_rds_cluster.nexus[0].endpoint : null
}

output "reader_endpoint" {
  value = var.is_nexus_obp_running ? aws_rds_cluster.nexus[0].reader_endpoint : null
}
