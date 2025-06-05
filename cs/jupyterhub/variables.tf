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

variable "jupyterhub_nginx_port" {
  type = number
}

variable "jupyterhub_port" {
  type = number
}

variable "jupyterhub_sg_name" {
  type = string
}

variable "jupyterhub_sg_efs_name" {
  type = string
}

variable "jupyterhub_target_group_name" {
  type = string
}

variable "jupyterhub_listener_rule_priority" {
  type = number
}

variable "jupyterhub_base_path" {
  type = string
}

variable "jupyterhub_private_subnet" {
  type = string
}

variable "jupyterhub_ec2_type" {
  type        = string
  description = "JupyterHub service Amazon EC2 Instance type"
}

variable "jupyterhub_ec2_config_template" {
  type        = string
  description = "JupyterHub service Amazon EC2 Instance type"
}

variable "jupyterhub_ec2_operating_system" {
  type        = string
  description = "JupyterHub service Amazon EC2 Instance type"
}

variable "jupyterhub_secrets_arn" {
  type        = string
  description = "ARN of the JupyterHub secrets manager"
  sensitive   = false
}
