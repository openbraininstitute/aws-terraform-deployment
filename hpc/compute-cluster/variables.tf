variable "aws_region" {
  type = string
}

variable "create_jumphost" {
  type    = bool
  default = false
}

variable "create_compute_instances" {
  type    = bool
  default = false
}

variable "compute_instance_type" {
  type = string
}

variable "num_compute_instances" {
  type        = number
  default     = 0
  description = "How many compute instances to create. Will be ignored if create_compute_instances is false"
}

variable "compute_subnet_id" {
  type = string
}

variable "compute_hpc_sg_id" {
  type = string
}

variable "jumphost_sg_id" {
  type = string
}

variable "compute_subnet_public_id" {
  type = string
}
