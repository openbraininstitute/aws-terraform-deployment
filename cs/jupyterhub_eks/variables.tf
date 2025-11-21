variable "jupyterhub_eks_public_a_cidr" {
  type      = string
  sensitive = false
}

variable "jupyterhub_eks_public_b_cidr" {
  type      = string
  sensitive = false
}

variable "jupyterhub_eks_private_a_cidr" {
  type      = string
  sensitive = false
}

variable "jupyterhub_eks_private_b_cidr" {
  type      = string
  sensitive = false
}

variable "vpc_id" {
  description = "VPC ID for JupyterHub EKS subnets"
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

variable "route_table_private_subnets_id" {
  description = "Route table ID for private subnets"
  type        = string
  sensitive   = false
}

variable "route_table_public_subnets_id" {
  description = "Route table ID for public subnets"
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
