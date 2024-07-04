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

variable "aws_account_id" {
  type        = string
  description = "ID of the AWS Account in which all Nexus components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "AWS Region in which all Nexus components will be deployed."
}
