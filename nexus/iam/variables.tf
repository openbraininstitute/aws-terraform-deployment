variable "dockerhub_username" {
  type    = string
  default = "bbpcinisedeploy"
}

variable "dockerhub_password" {
  type      = string
  sensitive = true
}

variable "aws_account_id" {
  type        = string
  description = "The ID of the AWS Account in which all Nexus components will be deployed."
}

variable "aws_region" {
  type        = string
  description = "The AWS Region in which all Nexus components will be deployed."
}