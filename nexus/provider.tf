terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.7.0"
    }
  }
}

variable "default_tags" {
  default = {
    SBO_Billing = "nexus"
  }
}

variable "openscience" {
  default = {
    SBO_Billing = "nexus-openscience"
  }
}

#########
## OBP ##
#########
provider "aws" {
  default_tags {
    tags = var.default_tags
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_ship_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "ship"
      }
    )
  }
  region = "us-east-1"
}
