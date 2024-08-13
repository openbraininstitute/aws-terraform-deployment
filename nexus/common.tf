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

  aws_region     = var.aws_region
  aws_account_id = var.aws_account_id

  nexus_secrets_arn  = var.nexus_secrets_arn
  dockerhub_password = var.dockerhub_password
}