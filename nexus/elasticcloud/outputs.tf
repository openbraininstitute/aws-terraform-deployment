output "http_endpoint" {
  value = "https://${ec_deployment.deployment.alias}.es.${var.elastic_hosted_zone_name}"
}

output "http_endpoint_ec2" {
  value = "https://${ec_deployment.deployment_ec2.alias}.es.${var.elastic_hosted_zone_name}"
}

output "elastic_user_credentials_secret_arn" {
  value = aws_secretsmanager_secret.elastic_password.arn
}