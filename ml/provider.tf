provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "machinelearning"
    }
  }
  region = var.aws_region
}

