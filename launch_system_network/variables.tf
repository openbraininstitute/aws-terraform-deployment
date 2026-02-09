variable "aws_region" {
  type = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "tags" {
  description = "Tags of the resources."
  type        = map(string)
  default     = { SBO_Billing = "launch_system" }
}

variable "internet_access_route_id" {
  type = string
}
