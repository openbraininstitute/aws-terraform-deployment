variable "nexus_fusion_hostname" {
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

variable "nat_gateway_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "unique_listener_priority" {
  type        = number
  description = "globally unique listener priority for the listener that will forward to the created target group"
}

variable "public_lb_listener_https_arn" {
  type        = string
  description = "ARN of the public listener (used by the public load balancer). We attach to this listener different listener rules which define when a request that hits the load balancer should be forwarded to Delta or Fusion."
}

variable "public_load_balancer_dns_name" {
  type        = string
  description = "DNS name of the public load balancer. We use this DNS name when creating records for Delta; a CNAME record to resolve the Delta record to the public load balancer DNS."
}