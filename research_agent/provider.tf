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
      SBO_Billing = "research_agent"
    }
  }
  region = var.aws_region
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}
