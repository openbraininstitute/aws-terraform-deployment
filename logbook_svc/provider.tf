terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# No provider block: the caller passes aws.logbook in, since a module with its own provider can't use count.
