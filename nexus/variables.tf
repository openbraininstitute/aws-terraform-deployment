### Required Infrastructure Information

variable "aws_region" {
  type        = string
  description = "The AWS Region in which all Nexus components will be deployed."
}

variable "account_id" {
  type        = string
  description = "The ID of the AWS Account in which all Nexus components will be deployed."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which all Nexus components will be deployed."
}

variable "dockerhub_username" {
  type    = string
  default = "bbpcinisedeploy"
}

variable "domain_name" {
  type = string
}

variable "nexus_obp_bucket_name" {
  type = string
}

variable "nexus_openscience_bucket_name" {
  type = string
}

variable "nexus_ship_bucket_name" {
  type        = string
  description = "The Nexus Ship bucket"
}

variable "dockerhub_password" {
  type      = string
  sensitive = true
}

variable "nat_gateway_id" {
  type        = string
  description = "The ID of the NAT gateway that is used when routing traffic out of the AWS Network."
}

variable "domain_zone_id" {
  type        = string
  description = "The ID of the Domain Zone (AWS Route53) in which to register the domain records."
}

variable "allowed_source_ip_cidr_blocks" {
  type        = list(string)
  description = "A list of allowed CIDR blocks. This is used in order to restrict which ranges can make calls to Nexus Delta and Nexus Fusion."
}

variable "private_lb_listener_https_arn" {
  type        = string
  description = "ARN of the private listener (used by the private load balancer). We attach to this listener different listener rules which define when a request that hits the load balancer should be forwarded to Delta or Fusion."
}

variable "readonly_access_policy_statement_part1" {
  description = "Policy for read-only permission pt1"
  type        = string
}

variable "readonly_access_policy_statement_part2" {
  description = "Policy for read-only permission pt2"
  type        = string
}

variable "aws_ssoadmin_instances_arns" {
  description = "ARN of the ssoadmin instances"
  type        = list(string)
}

variable "is_production" {
  type = bool
}
