data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "vpc_id" {
  type        = string
  description = "VPC ID where JupyterHub resources will be deployed"
}

variable "aws_coreservices_ssh_key_id" {
  type        = string
  description = "Name of the AWS key pair used for SSH access"
}

variable "private_alb_https_listener_arn" {
  type        = string
  description = "ARN of the private ALB HTTPS listener to attach the JupyterHub rule to"
}

variable "primary_domain" {
  type        = string
  description = "Primary domain name used for JupyterHub and Keycloak URLs"
}

variable "jupyterhub_nginx_port" {
  type = number
}

variable "jupyterhub_port" {
  type = number
}

variable "jupyterhub_admin_users" {
  type        = list(string)
  description = "List of usernames to grant JupyterHub admin privileges"
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
  type        = string
  description = "Base URL path for JupyterHub (e.g. /jupyter)"
}

variable "jupyterhub_private_subnet" {
  type        = string
  description = "Subnet ID of the private subnet where the JupyterHub EC2 instance will be placed"
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
  sensitive   = true
}

variable "jupyterhub_ec2_root_volume_size" {
  type        = number
  description = "Root EBS volume size in GB for the JupyterHub EC2 instance"
  default     = 20
}
