data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "is_staging" {
  description = "Whether deployment is happening in staging"
  type        = bool
  default     = false
}

variable "is_production" {
  type    = bool
  default = false
}

variable "route_table_private_subnets_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "aws_coreservices_ssh_key_id" {
  type = string
}

variable "private_alb_https_listener_arn" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "domain_name" {
  type      = string
  sensitive = false
}

variable "keycloak_secrets_arn" {
  type        = string
  description = "ARN of the Keycloak secrets manager"
  sensitive   = false
}

variable "keycloak_task_size" {
  type = object({
    cpu    = number
    memory = number
  })

  description = "CPU and memory limit for Keycloak's ECS task (number or string format)"
}

variable "jupyterhub_secrets_arn" {
  type        = string
  description = "ARN of the JupyterHub secrets manager"
  sensitive   = false
}

variable "jupyterhub_ec2_type" {
  type        = string
  description = "JupyterHub service Amazon EC2 Instance type"
}

variable "route_table_public_subnets_id" {
  description = "Route table ID for public subnets"
  type        = string
  sensitive   = false
}

variable "aws_region" {
  description = "AWS region for availability zones"
  type        = string
  sensitive   = false
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block for network ACL rules"
  type        = string
  sensitive   = false
}

variable "nat_gateway_id" {
  description = "NAT Gateway ID"
  type        = string
  sensitive   = false
}

variable "aws_endpoints_subnet_cidr" {
  description = "CIDR of the network containing the interface endpoints"
  type        = string
  sensitive   = false
}

variable "private_alb_cidr_a" {
  description = "CIDR of the first subnet for the private ALB"
  type        = string
  sensitive   = false
}

variable "private_alb_cidr_b" {
  description = "CIDR of the second subnet for the private ALB"
  type        = string
  sensitive   = false
}
