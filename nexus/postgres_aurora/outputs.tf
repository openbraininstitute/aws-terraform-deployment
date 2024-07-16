output "writer_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = module.aurora_postgresql.cluster_endpoint
}

output "reader_endpoint" {
  description = "A read-only endpoint for the cluster, automatically load-balanced across replicas"
  value       = module.aurora_postgresql.cluster_reader_endpoint
}