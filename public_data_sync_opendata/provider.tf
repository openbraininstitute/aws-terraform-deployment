terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.uswest2]
    }
    awscc = {
      source                = "hashicorp/awscc"
      configuration_aliases = [awscc.uswest2]
    }
  }
}
