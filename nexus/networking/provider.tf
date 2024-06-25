provider "aws" {
  default_tags {
    tags = {
      Nexus       = "networking"
      SBO_Billing = "nexus"
    }
  }
  region = var.aws_region
}