provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "viz"
    }
  }
  region = "us-east-1"
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~>5.0"
    }
  }
}
