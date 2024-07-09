provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "nexus"
      Nexus       = "blazegraph"
    }
  }
  region = var.aws_region
}
