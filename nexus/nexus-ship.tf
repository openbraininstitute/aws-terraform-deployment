module "ship" {
  source = "./ship"

  providers = {
    aws = aws.nexus_ship_tags
  }

  dockerhub_credentials_arn   = module.iam.dockerhub_credentials_arn
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn           = aws_secretsmanager_secret.nexus_secrets.arn
  postgres_host               = "https://replace.this.postgres.host"
  postgres_database           = "nexusobp"
  postgres_username           = "nexusobp"
  target_base_uri             = "https://${var.domain_name}/api/delta/v1"
  target_bucket               = aws_s3_bucket.nexus_obp.id
  target_bucket_arn           = aws_s3_bucket.nexus_obp.arn
  nexus_ship_bucket_name      = var.nexus_ship_bucket_name
  aws_region                  = var.aws_region
}
