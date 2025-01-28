variable "svc_name" {
  type        = string
  description = "Service name which will be used to identify related resources as well as a role prefix."
}

variable "aws_region" {
  type        = string
  description = "AWS region where the service will be deployed."
}

variable "account_id" {
  type        = string
  description = "AWS account id."
}

variable "vpc_id" {
  type        = string
  description = "ID of the main VPC"
}

variable "svc_image" {
  type        = string
  description = "Docker image for the service."
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "domain_name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "JSON schema for websocket incoming message validation."
}

variable "kc_scr" {
  type        = string
  description = "Tmp, remove."
}

variable "id_rsa_scr" {
  type        = string
  description = "Tmp, remove."
}

variable "hpc_head_node" {
  type        = string
  description = "Tmp, remove."
}

variable "nexus_domain_name" {
  type        = string
  description = "Nexus service domain name"
}
