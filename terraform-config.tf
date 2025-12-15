terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55, != 5.71.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.53.0"
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

provider "awscc" {
  region = "us-east-1"
}

provider "aws" {
  region = "us-west-2"
  alias  = "uswest2"
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
}
