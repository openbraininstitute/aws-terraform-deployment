variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_alb_listener_arn" {
  type = string
}

variable "alb_listener_rule_priority" {
  type    = number
  default = 770
}

variable "internet_access_route_id" {
  type        = string
  description = "Route table ID with NAT gateway for internet access"
}

variable "private_alb_cidr_a" {
  type        = string
  description = "CIDR of private ALB subnet A (for NACL rules)"
}

variable "private_alb_cidr_b" {
  type        = string
  description = "CIDR of private ALB subnet B (for NACL rules)"
}

variable "aws_endpoints_subnet_cidr" {
  type        = string
  description = "CIDR of the AWS VPC endpoints subnet (ECR, CloudWatch, etc.)"
}

variable "docker_image_url" {
  type        = string
  description = "Docker image URL for the grading service API"
}

variable "base_path" {
  type        = string
  description = "Base path for the API (e.g. /api/grading-service)"
}

variable "tags" {
  type    = map(string)
  default = { SBO_Billing = "grading_service" }
}
