data "terraform_remote_state" "common" {
  backend = "http"
  config = {
    address        = "https://bbpgitlab.epfl.ch/api/v4/projects/2295/terraform/state/default"
    lock_address   = "https://bbpgitlab.epfl.ch/api/v4/projects/2295/terraform/state/default/lock"
    lock_method    = "POST"
    password       = var.common_token_pass
    unlock_address = "https://bbpgitlab.epfl.ch/api/v4/projects/2295/terraform/state/default/lock"
    username       = var.common_token_name
  }
}

variable "common_token_name" {
  description = "The token name needed to access the deployment-common repository."
  type        = string
  sensitive   = true

}

variable "common_token_pass" {
  description = "The token password needed to access the deployment-common repository."
  type        = string
  sensitive   = true
}
