output "http_endpoint" {
  value = "https://${ec_deployment.deployment.alias}.es.${aws_route53_zone.nexus_es_zone.name}"
}