variable "default_tags" {
  default = {
    SBO_Billing = "nexus"
  }
}

provider "aws" {
  default_tags {
    tags = var.default_tags
  }
  region = var.aws_region
}

provider "aws" {
  alias  = "nexus_fusion_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus       = "fusion"
      }
    )
  }
  region = var.aws_region
}

provider "aws" {
  alias  = "nexus_postgres_tags"
  default_tags {
    tags = merge(
      var.default_tags,
      {
        Nexus       = "postgres"
      }
    )
  }
  region = var.aws_region
}
