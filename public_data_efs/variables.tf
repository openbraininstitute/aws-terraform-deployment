variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "access_point_subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "entitycore_internal_bucket" {
  type        = string
  description = "S3 bucket name in which entitycore data lives."
}

variable "entitycore_internal_region" {
  type        = string
  description = "S3 region name in which entitycore data lives."
}

variable "opendata_bucket" {
  type        = string
  description = "S3 bucket name in which open data lives."
}

variable "opendata_region" {
  type        = string
  description = "S3 region name in which open data lives."
}

variable "internal_public_data_mountpath" {
  type        = string
  description = "Path on which internal public data will be available in EFS"
}

variable "opendata_mountpath" {
  type        = string
  description = "Path on which opendata will be available in EFS"
}

variable "opendata_paths_list" {
  type        = string
  description = "File in which the paths to sync on opendata are listed, one per line"
}
