provider "aws" {
  default_tags {
    tags = {
      Nexus       = "fusion"
      SBO_Billing = "nexus"
    }
  }
  region = var.aws_region
}