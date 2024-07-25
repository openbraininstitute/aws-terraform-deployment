variable "nexus_postgresql_name" {
  type = string
}

variable "nexus_postgresql_engine_version" {
  type    = string
  default = "16.2"
}

variable "subnets_ids" {
  type = list(string)
}

variable "min_capacity" {
  type    = number
  default = 2
}

variable "max_capacity" {
  type    = number
  default = 8
}

variable "nexus_postgresql_database_name" {
  type = string
}

variable "nexus_database_username" {
  type = string
}

variable "nexus_database_password_arn" {
  type        = string
  description = "the arn of the secret containing the password for the nexus database"
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus_postgresql_password-jRsJRc"
}

variable "security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

variable "vpc_id" {
  type        = string
  description = "The ID of the provided VPC in which all Nexus components will be deployed."
}