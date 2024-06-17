provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
  region = var.aws_region
}

