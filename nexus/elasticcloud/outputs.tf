output "http_endpoint" {
  value = "https://${ec_deployment.deployment.alias}.es.${var.elastic_hosted_zone_name}"
}