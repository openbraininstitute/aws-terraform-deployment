output "aws_ecs_cluster_nexus_arn" {
  value = length(aws_ecs_cluster.nexus) > 0 ? aws_ecs_cluster.nexus[0].arn : null
}

output "aws_ecs_cluster_nexus_openscience_arn" {
  value = length(aws_ecs_cluster.nexus_openscience) > 0 ? aws_ecs_cluster.nexus_openscience[0].arn : null
}

output "aws_service_discovery_http_namespace_nexus_arn" {
  value = length(aws_service_discovery_http_namespace.nexus) > 0 ? aws_service_discovery_http_namespace.nexus[0].arn : null
}

output "aws_service_discovery_http_namespace_nexus_openscience_arn" {
  value = length(aws_service_discovery_http_namespace.nexus_openscience) > 0 ? aws_service_discovery_http_namespace.nexus_openscience[0].arn : null
}
