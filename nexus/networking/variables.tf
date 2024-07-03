variable "aws_region" {
  type        = string
  description = "The AWS Region in which all Nexus components will be deployed."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the provided VPC in which all Nexus components will be deployed."
}

variable "nat_gateway_id" {
  type        = string
  default     = ""
  description = "The ID of the provided NAT gateway that is used when routing traffic out of the AWS Network."
}
