variable "secret_with_ro_db_credentials_arn" {
  type        = string
  description = "ARN of the secret containing a username and password for read-only access to the database. The secret needs to have 2 keys: 'username' and 'password'"
}

variable "spill_bucket_name" {
  type        = string
  description = "Name for the s3 bucket for the 'spill' of database queries"
}

variable "spill_prefix" {
  type        = string
  description = "Prefix for the 'spill' of database queries within the s3 bucket"
}

variable "rds_db_subnet_az" {
  type        = string
  description = "Availability zone of the subnet where the RDS database is located"
}

variable "rds_db_subnet_id" {
  type        = string
  description = "ID of the subnet where the RDS database is located"
}

variable "db_host" {
  type        = string
  description = "Hostname for the RDS database"
}

variable "db_port" {
  type        = number
  description = "Port for the RDS database"
}

variable "db_database_name" {
  type        = string
  description = "Name of the database in RDS"
}

variable "connection_type" {
  type        = string
  description = "Type of connection to use. Currently only tested with POSTGRESQL"
}

variable "expire_spill_objects_after_num_days" {
  type        = number
  description = "Number of days after which the spill objects can be deleted"
}

# variable "jdbc_driver_name" {
#   type        = string
#   description = "Name of the JDBC driver to use for connecting to RDS"
# }

variable "vpc_id" {
  type        = string
  description = "ID of the VPC"
}

variable "name_prefix" {
  type        = string
  description = "Prefix used in names of roles and so on to make sure they are unique"
}
