variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnets_ids" {
  type = list(string)
}

variable "create_nexus_database" {
  type    = bool
  default = true
}

variable "instance_class" {
  type = string
}

variable "read_replica_instance_class" {
  type = string
}

variable "nexus_postgresql_database_name" {
  type    = string
  default = "nexus_user"
}

variable "nexus_postgresql_database_username" {
  type    = string
  default = "nexus_user"
}

#variable "nexus_postgresql_database_password" {
#  type = string
#  sensitive = true
#}

variable "nexus_postgresql_database_password_arn" {
  type        = string
  description = "the arn of the secret containing the password for the nexus database"
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus_postgresql_password-jRsJRc"
}

variable "subnet_security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

#variable "nexus_postgresql_admin_username" {
#  type    = string
#  default = "admin"
#}

#variable "nexus_postgresql_admin_password" {
#  type      = string
#  sensitive = true
#}