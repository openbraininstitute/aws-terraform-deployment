provider "aws" {
  default_tags {
    tags = {
      Nexus       = "ship"
      SBO_Billing = "nexus_ship"
    }
  }
  region = var.aws_region
}