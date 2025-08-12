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
