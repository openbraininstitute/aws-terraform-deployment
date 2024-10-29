module "networking" {
  source = "./networking"

  providers = {
    aws = aws.nexus_networking_tags
  }

  aws_region     = var.aws_region
  nat_gateway_id = var.nat_gateway_id
  vpc_id         = var.vpc_id
}

module "iam" {
  source = "./iam"

  providers = {
    aws = aws.nexus_iam_tags
  }

  aws_region = var.aws_region
  account_id = var.account_id

  nexus_secrets_arn  = aws_secretsmanager_secret.nexus_secrets.arn
  dockerhub_password = var.dockerhub_password
}
