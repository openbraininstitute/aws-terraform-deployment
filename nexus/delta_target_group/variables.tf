variable "nexus_delta_hostname" {
  type = string
}

variable "target_group_prefix" {
  type        = string
  description = "unique prefix (max 6 characters) for the target group"
}

variable "vpc_id" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "aws_lb_listener_sbo_https_arn" {
  type = string
}

variable "aws_lb_alb_dns_name" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}