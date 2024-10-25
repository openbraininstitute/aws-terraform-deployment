terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55, != 5.71.0"
    }
    ec = {
      source  = "elastic/ec"
      version = "~> 0.9.0"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
}

provider "ec" {
}
