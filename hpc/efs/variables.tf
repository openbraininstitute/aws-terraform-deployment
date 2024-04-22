variable "aws_region" {
  type = string
}

variable "compute_subnet_a_id" {
  type = string
}

variable "compute_efs_sg_id" {
  type = string
}

variable "create_compute_instances" {
  type = bool
}

variable "compute_subnet_ids" {
  type = list(string)
}

variable "av_zone_suffixes" {
  type = list(string)
}
