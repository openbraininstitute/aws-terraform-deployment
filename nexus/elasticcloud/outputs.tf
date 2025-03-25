output "http_endpoint_ec2" {
  value = "https://${ec_deployment.deployment_ec2.alias}.es.${var.elastic_hosted_zone_name}"
}

output "elastic_user_credentials_secret_arn_ec2" {
  value = aws_secretsmanager_secret.elastic_password_ec2.arn
}
