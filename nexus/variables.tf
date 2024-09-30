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

variable "nexus_obp_bucket_name" {
  type = string
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

variable "public_load_balancer_dns_name" {
  type        = string
  description = "DNS name of the public load balancer. We use this DNS name when creating records for Delta and Fusion; a CNAME record to resolve Delta & Fusion records to the public load balancer DNS."
}

variable "public_lb_listener_https_arn" {
  type        = string
  description = "ARN of the public listener (used by the public load balancer). We attach to this listener different listener rules which define when a request that hits the load balancer should be forwarded to Delta or Fusion."
}

variable "nexus_secrets_arn" {
  default     = "arn:aws:secretsmanager:us-east-1:671250183987:secret:nexus_app-xfJP5F"
  type        = string
  description = "The ARN of the SBO nexus app secrets"
}
