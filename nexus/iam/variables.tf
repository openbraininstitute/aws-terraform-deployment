variable "dockerhub_username" {
  type        = string
  default     = "bbpcinisedeploy"
  description = "Dockerhub username to use to authenticate docker image pulls."
}

variable "dockerhub_password" {
  type        = string
  sensitive   = true
  description = "Dockerhub password to use to authenticate docker image pulls."
}

variable "account_id" {
  type        = string
  description = "ID of the AWS Account in which all Nexus components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS Region in which all Nexus components will be deployed."
}

variable "secret_recovery_window_in_days" {
  type        = number
  default     = 7
  description = "The recovery window for the secrets created by this module. It is useful mainly to set to 0 in sandbox so that the secrets are deleted instantly there."
}