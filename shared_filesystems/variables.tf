variable "vpc_id" {
  description = "ID of the VPC where EFS will be created"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs where EFS mount targets will be created"
  type        = list(string)
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC"
  type        = string
}
