variable "target_group_prefix" {
  type        = string
  description = "Unique prefix (max 6 characters) for the target group."
}

variable "unique_listener_priority" {
  type        = number
  description = "Globally unique listener priority for the listener that will forward to the created target group."
}

variable "base_path" {
  type        = string
  description = "The base path for the service"
  sensitive   = false
}

variable "target_port" {
  type        = number
  description = "Port on which targets receive traffic"
}

variable "health_check_enabled" {
  type    = bool
  default = true
}

variable "health_check_path" {
  type = string
}

variable "health_check_code" {
  type    = string
  default = "200"
}

variable "allowed_source_ip_cidr_blocks" {
  type        = list(string)
  description = "A list of allowed CIDR blocks. This is used in order to restrict which ranges can make calls to Nexus Delta."
}

variable "public_lb_listener_https_arn" {
  type        = string
  description = "ARN of the public listener (used by the public load balancer). We attach to this listener different listener rules which define when a request that hits the load balancer should be forwarded to Delta or Fusion."
}

variable "nat_gateway_id" {
  type = string
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which the target group will be deployed."
}
