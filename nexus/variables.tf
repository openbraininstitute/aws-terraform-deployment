### Required Infrastructure Information

variable "aws_region" {
  type        = string
  description = "The AWS Region in which all Nexus components will be deployed."
}

variable "aws_account_id" {
  type        = string
  description = "The ID of the AWS Account in which all Nexus components will be deployed."
}

variable "vpc_id" {
  type        = string
  description = "The ID of the VPC in which all Nexus components will be deployed."
}

variable "dockerhub_access_iam_policy_arn" {
  type        = string
  description = "The ARN of the IAM policy that allows to access the Dockerhub credentials stored in AWS Secrets Manager. See also the description of the dockerhub_credentials_arn variable."
}

variable "dockerhub_credentials_arn" {
  type        = string
  description = "The ARN of the secret in Secrets Manager that contains the Dockerhub credentials that can be used to pull images while being authenticated."
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

### Nexus Fusion ###

variable "nexus_fusion_hostname" {
  default   = "sbo-nexus-fusion.shapes-registry.org"
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:1.9.9"
  sensitive = false
  type      = string
}