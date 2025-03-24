terraform {
  required_providers {
    ec = {
      source                = "elastic/ec"
      configuration_aliases = [ec.ec2]
    }
  }
}
