terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "accounting"
    }
  }
  region = var.aws_region
}
