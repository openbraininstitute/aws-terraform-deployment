provider "aws" {
  default_tags {
    tags = {
      SBO_Billing = "nexus"
      Nexus       = "delta"
    }
  }
  region = var.aws_region
}
