terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "core_webapp_preview"
    }
  }
  region = var.aws_region
}
