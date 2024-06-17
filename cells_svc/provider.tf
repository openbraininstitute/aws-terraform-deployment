provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "cell_svc"
    }
  }
  region = var.aws_region
}

