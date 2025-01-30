output "aws_ecs_cluster_nexus_arn" {
  value = aws_ecs_cluster.nexus[0].arn
}

output "aws_ecs_cluster_nexus_openscience_arn" {
  value = aws_ecs_cluster.nexus_openscience[0].arn
}

output "aws_service_discovery_http_namespace_nexus_arn" {
  value = aws_service_discovery_http_namespace.nexus[0].arn
}

output "aws_service_discovery_http_namespace_nexus_openscience_arn" {
  value = aws_service_discovery_http_namespace.nexus_openscience[0].arn
}
