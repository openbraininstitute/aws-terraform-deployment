terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "bluenaas"
    }
  }
  region = var.aws_region
}
