data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "aws_coreservices_ssh_key_id" {
  type = string
}

variable "private_alb_https_listener_arn" {
  type = string
}

variable "primary_domain" {
  type = string
}

variable "jupyterhub_port" {
  type = number
}

variable "jupyterhub_base_path" {
  type = string
}

variable "jupyterhub_private_subnet" {
  type = string
}

variable "jupyterhub_secrets_arn" {
  type        = string
  description = "ARN of the JupyterHub secrets manager"
  sensitive   = false
}
