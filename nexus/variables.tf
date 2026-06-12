### Required Infrastructure Information
variable "nexus_obp_bucket_name" {
  type = string
}

variable "nexus_openscience_bucket_name" {
  type = string
}

variable "nexus_ship_bucket_name" {
  type        = string
  description = "The Nexus Ship bucket"
}

variable "temporary_read_user_arn" {
  type        = string
  description = "ARN for temporary user with read access to the openscience bucket"
}
