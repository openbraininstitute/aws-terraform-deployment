variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "keycloak_bucket_name" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "efs_mt_subnets" {
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

variable "public_alb_listener" {
  type = string
}
variable "db_instance_class" {
  type = string
}

# This is the subnet where ECS service will be running
variable "private_subnets" {
  type    = list(string)
  default = ["subnet-03e6e9df2641a2e47"]
}

# Currently using opened SG, the same one as used for efs (efs_sg) - hardcoded in service.tf, not in use
variable "security_groups" {
  type    = list(string)
  default = ["sg-00d229cdb6f4e0dc6"]
}

#Subnet for datasync task - subnet-03e6e9df2641a2e47 - cs_subnet us-east-1a
variable "datasync_subnet_arn" {
  type    = string
  default = "arn:aws:ec2:us-east-1:671250183987:subnet/subnet-03e6e9df2641a2e47"
}

variable "keycloak_postgresql_database_password_arn" {
  type    = string
  default = "arn:aws:secretsmanager:us-east-1:671250183987:secret:keycloak_postgresql_password-o9Ybhb"
}
