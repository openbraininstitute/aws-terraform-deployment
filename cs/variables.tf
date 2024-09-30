variable "vpc_id" {
  type = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "route_table_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "keycloak_bucket_name" {
  type = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "public_alb_listener" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "preferred_hostname" {
  type        = string
  description = "preferred hostname to which requests for /auth should be redirected if the host is any of the redirect_hostnames"
  sensitive   = false
}

variable "redirect_hostnames" {
  type        = list(string)
  description = "hostnames which should be redirected to the preferred hostname if there's a request for /auth"
  sensitive   = false
}
