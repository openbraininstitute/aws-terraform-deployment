variable "internal_public_data_mountpath" {
  type        = string
  description = "Path on which internal public data will be available in EFS"
}

variable "opendata_mountpath" {
  type        = string
  description = "Path on which opendata will be available in EFS"
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "access_point_subnet_ids" {
  type = list(string)
}
