provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "kg_inference_api"
    }
  }
  region = var.aws_region
}

