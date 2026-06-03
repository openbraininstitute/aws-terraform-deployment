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
      SBO_Billing = "entitycore"
    }
  }
  region = var.aws_region
}
