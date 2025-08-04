# we are decomm Nexus, this code will be deleted soon
output "http_endpoint_ec2" {
  value = var.is_nexus_obp_running ? "https://${ec_deployment.deployment_ec2[0].alias}.es.${var.elastic_hosted_zone_name}" : null
}

output "elastic_user_credentials_secret_arn_ec2" {
  value = aws_secretsmanager_secret.elastic_password_ec2.arn
}
