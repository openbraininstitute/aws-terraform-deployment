terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    awscc = {
      source  = "hashicorp/awscc"
      version = "~> 1.75.0"
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

provider "awscc" {
  region = "us-west-2"
  alias  = "uswest2"
}

provider "aws" {
  alias = "launch-system"
  default_tags {
    tags = {
      SBO_Billing = "launch_system"
    }
  }
}

# Was the module's own provider; a module with count must get it from here.
provider "aws" {
  alias  = "thumbnail-generation-api"
  region = "us-east-1" # the default provider's region, which var.aws_region was
  default_tags {
    tags = {
      SBO_Billing = "thumbnail_generation_api"
    }
  }
}

provider "aws" {
  alias = "networking"
  default_tags {
    tags = {
      SBO_Billing = "common:networking"
    }
  }
}
