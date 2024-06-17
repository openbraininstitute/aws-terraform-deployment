provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "thumbnail_generation_api"
    }
  }
  region = var.aws_region
}

