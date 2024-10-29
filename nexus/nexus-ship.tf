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
  target_base_uri             = "https://openbluebrain.com/api/delta/v1"
  target_bucket               = "nexus-obp-production"
  target_bucket_arn           = aws_s3_bucket.nexus_obp.arn
  aws_region                  = var.aws_region
}
