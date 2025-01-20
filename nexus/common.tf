module "networking" {
  source = "./networking"

  nexus_az_letter_id = var.nexus_az_letter_id

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

  dockerhub_password = var.dockerhub_password
}
