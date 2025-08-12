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
  alias = "nexus_blazegraph_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "blazegraph"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_delta_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "delta"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_fusion_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "fusion"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_iam_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "iam"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_networking_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "networking"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_postgres_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "postgres"
      }
    )
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

provider "aws" {
  alias = "nexus_dashboard_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus = "dashboard"
      }
    )
  }
  region = "us-east-1"
}

#################
## Openscience ##
#################

provider "aws" {
  alias = "nexus_openscience_postgres_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "postgres"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_openscience_blazegraph_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "blazegraph"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_openscience_delta_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "delta"
      }
    )
  }
  region = "us-east-1"
}

provider "aws" {
  alias = "nexus_openscience_fusion_tags"
  default_tags {
    tags = merge(
      var.openscience,
      {
        Nexus = "fusion"
      }
    )
  }
  region = "us-east-1"
}
