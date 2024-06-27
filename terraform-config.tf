terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
    ec = {
      source  = "elastic/ec"
      version = "~> 0.9.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
}

provider "ec" {
}
