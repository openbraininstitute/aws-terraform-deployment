variable "cluster_identifier" {
  type = string
}

variable "subnets_ids" {
  type = list(string)
}

variable "instance_class" {
  type = string
}

variable "nexus_postgresql_engine_version" {
  type    = string
  default = "15"
}

variable "nexus_postgresql_database_name" {
  type    = string
  default = "nexus_user"
}

variable "nexus_postgresql_database_username" {
  type    = string
  default = "nexus_user"
}

variable "nexus_secrets_arn" {
  type        = string
  description = "the arn of the secret containing the password for the nexus database"
}

variable "security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

