output "http_endpoint" {
  value = "https://${ec_deployment.deployment.name}.es.${aws_route53_zone.nexus_es_zone.name}"
}