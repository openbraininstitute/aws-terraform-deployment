
variable "compute_efs_sg_id" {
  type = string
}

variable "av_zone_suffixes" {
  type = list(string)
}

variable "compute_subnet_efs_ids" {
  type = list(string)
}
