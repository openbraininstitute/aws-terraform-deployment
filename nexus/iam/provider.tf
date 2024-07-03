provider "aws" {
  default_tags {
    tags = {
      Nexus       = "iam"
      SBO_Billing = "nexus"
    }
  }
  region = var.aws_region
}