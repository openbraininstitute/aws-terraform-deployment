provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "common"
    }
  }
  region = data.aws_region.current.name
}

