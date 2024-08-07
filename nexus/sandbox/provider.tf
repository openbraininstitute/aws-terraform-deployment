terraform {
  required_providers {
    ec = {
      source  = "elastic/ec"
      version = "~> 0.9.0"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region" {
  type      = string
  default   = "us-east-1"
  sensitive = false
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
}

data "aws_secretsmanager_secret_version" "ec_api_key" {
  secret_id = local.ec_api_key_arn
}

provider "ec" {
  apikey = data.aws_secretsmanager_secret_version.ec_api_key.secret_string
}