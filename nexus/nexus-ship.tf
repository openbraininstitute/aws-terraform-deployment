module "ship" {
  source = "./ship"

  providers = {
    aws = aws.nexus_ship_tags
  }

  nexus_ship_bucket_name = var.nexus_ship_bucket_name
}
