terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# Provider configuration (including default_tags) is supplied by the
# caller as an aliased provider (aws.logbook, see terraform-config.tf):
# a module with its own provider block cannot use count at the call
# site, and logbook_enabled gates this module per environment (same
# reason as research_agent/provider.tf).
