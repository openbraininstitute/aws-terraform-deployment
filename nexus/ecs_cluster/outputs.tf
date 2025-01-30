output "aws_ecs_cluster_nexus_arn" {
  value = aws_ecs_cluster.nexus.arn
}

output "aws_ecs_cluster_nexus_openscience_arn" {
  value = aws_ecs_cluster.nexus_openscience.arn
}

output "aws_service_discovery_http_namespace_nexus_arn" {
  value = aws_service_discovery_http_namespace.nexus.arn
}

output "aws_service_discovery_http_namespace_nexus_openscience_arn" {
  value = aws_service_discovery_http_namespace.nexus_openscience.arn
}
