provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "viz"
    }
  }
  region = var.aws_region
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}
