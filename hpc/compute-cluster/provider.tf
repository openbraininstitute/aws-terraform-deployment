provider "aws" {
  default_tags {
    tags = {
      SBO_Billing  = "${var.sbo_billing}:parallelcluster"
      "obp:module" = var.sbo_billing
    }
  }
  region = var.aws_region
}