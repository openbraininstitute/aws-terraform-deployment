terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Provider configuration (including default_tags) is supplied by the
# caller as an aliased provider (aws.research_agent, see
# terraform-config.tf) - a module with its own local provider
# configuration cannot use count/for_each/depends_on at the call site.

data "aws_caller_identity" "current" {}

data "aws_vpc" "main" {
  id = var.vpc_id
}
