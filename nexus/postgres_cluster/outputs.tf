output "writer_endpoint" {
  value = aws_rds_cluster.nexus.endpoint
}

output "reader_endpoint" {
  value = aws_rds_cluster.nexus.reader_endpoint
}