provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "nexus"
    }
  }
  region = var.aws_region
}

