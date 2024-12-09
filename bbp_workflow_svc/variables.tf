variable "svc_name" {
  type        = string
  description = "Service name which will be used to identify related resources as well as a role prefix."
}

variable "aws_region" {
  type        = string
  description = "AWS region where the service will be deployed."
}

variable "ecs_subnet_id" {
  type        = string
  description = "Subnet where the service ECS components will be deployed."
}

variable "ecs_secgrp_id" {
  type        = string
  description = "Security group that the module will configure."
}

variable "account_id" {
  type        = string
  description = "AWS account id."
}

variable "svc_image" {
  type        = string
  description = "Docker image for the service."
}

variable "tags" {
  type        = map(string)
  description = "JSON schema for websocket incoming message validation."
}

variable "apigw_id" {
  type        = string
  description = "Tmp to get fixed url, remove."
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
