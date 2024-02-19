terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }
  required_version = ">= 1.5.0"
}

provider "aws" {
  profile = "viz-sandbox"
  region  = "us-east-1"
}
