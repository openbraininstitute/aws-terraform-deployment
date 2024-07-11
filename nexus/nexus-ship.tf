module "ship" {
  source = "./ship"

  dockerhub_credentials_arn   = module.iam.dockerhub_credentials_arn
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn
  nexus_secrets_arn           = var.nexus_secrets_arn
  postgres_host               = "https://replace.this.postgres.host"
  target_bucket_arn           = module.delta.nexus_delta_bucket_arn
  second_target_bucket_arn    = aws_s3_bucket.nexus.arn
  aws_region                  = var.aws_region
}
