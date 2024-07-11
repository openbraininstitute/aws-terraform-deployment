provider "aws" {
  default_tags {
    tags = {
      Nexus       = "postgres"
      SBO_Billing = "nexus"
    }
  }
  region = var.aws_region
}