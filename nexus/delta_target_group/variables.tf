variable "nexus_delta_hostname" {
  type        = string
  description = "The Delta hostname that will be registered as a record (a CNAME record pointing to the public load balancer)."
}

variable "target_group_prefix" {
  type        = string
  description = "Unique prefix (max 6 characters) for the target group."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the target group will be deployed."
}

variable "domain_zone_id" {
  type        = string
  description = "The ID of the Domain Zone (AWS Route53) in which to register the domain records."
}

variable "public_lb_listener_https_arn" {
  type        = string
  description = "ARN of the public listener (used by the public load balancer). We attach to this listener different listener rules which define when a request that hits the load balancer should be forwarded to Delta or Fusion."
}

variable "public_load_balancer_dns_name" {
  type        = string
  description = "DNS name of the public load balancer. We use this DNS name when creating records for Delta; a CNAME record to resolve the Delta record to the public load balancer DNS."
}

variable "nat_gateway_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type        = list(string)
  description = "A list of allowed CIDR blocks. This is used in order to restrict which ranges can make calls to Nexus Delta."
}

variable "unique_listener_priority" {
  type        = number
  description = "Globally unique listener priority for the listener that will forward to the created target group."
}

variable "aws_region" {
  type        = string
  description = "The AWS region in which the resources will be created."
}
