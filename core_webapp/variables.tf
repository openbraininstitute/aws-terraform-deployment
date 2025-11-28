variable "key" {
  type        = string
  description = "Unique key for the module instance, used as a suffix for resource names"
  sensitive   = false
}

variable "hostname" {
  default     = null
  type        = string
  description = "Hostname for the core webapp"
  sensitive   = false
}

variable "log_group_name" {
  type        = string
  description = "The log name within cloudwatch for the core webapp"
  sensitive   = false
}

variable "vpc_id" {
  type        = string
  sensitive   = false
  description = "ID of the VPC"
}

variable "ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for the SBO core webapp"
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB listener to which the listener rule should be added"
  sensitive   = false
}

variable "alb_listener_rule_priority" {
  type        = number
  description = "Priority of the ALB listener rule"
  sensitive   = false
}

variable "aws_region" {
  type      = string
  sensitive = false
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "subnet_cidr_block" {
  description = "CIDR block of the subnet"
  type        = string
  sensitive   = false
}

variable "docker_image_url" {
  type        = string
  description = "Docker image for the core webapp"
  sensitive   = false
}

variable "route_table_id" {
  type        = string
  description = "Route table for private networks"
  sensitive   = false
}

variable "allowed_source_ip_cidr_blocks" {
  type        = list(string)
  description = "List of CIDR blocks to allow access to the webapp"
}

variable "secrets_arn" {
  type        = string
  description = "Secrets ARN"
  sensitive   = false
}

variable "auth_url" {
  type        = string
  sensitive   = false
  description = "NextAuth endpoint URL"
}

variable "deployment_env" {
  type        = string
  sensitive   = false
  description = "Name of the deployment environment"
  validation {
    condition     = contains(["preview", "development", "staging", "production"], var.deployment_env)
    error_message = "Invalid deployment environment name"
  }
}

variable "sanity_dataset" {
  type        = string
  sensitive   = false
  description = "Sanity dataset name"
  validation {
    condition     = contains(["staging", "production"], var.sanity_dataset)
    error_message = "Invalid Sanity dataset name"
  }
}

variable "stripe_publishable_key" {
  type        = string
  sensitive   = false
  description = "Stripe publishable key"
}

variable "matomo_site_id" {
  type        = string
  sensitive   = false
  description = "Matomo site ID"
}

# TODO: Check if we still need domain redirects, clean up if not.
variable "primary_hostname" {
  type        = string
  sensitive   = false
  description = "Used for domain redirect, e.g. https://openbluebrain.com -> https://www.openbraininstitute.org/"
}

variable "api_origin" {
  type        = string
  sensitive   = false
  description = "Default origin for all API services"
}

variable "keycloak_issuer" {
  type        = string
  sensitive   = false
  description = "Keycloak issuer URL"
}

# S3 and CloudFront Configuration Variables
variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket for core webapp assets"
  sensitive   = false
}

variable "s3_bucket_allowed_origins" {
  type        = list(string)
  description = "Allowed CORS origins for the S3 bucket"
}

variable "cloudfront_aliases" {
  type        = list(string)
  description = "List of domain aliases for CloudFront distribution"
  default     = null
  sensitive   = false
}

variable "cloudfront_certificate_arn" {
  type        = string
  description = "ARN of ACM certificate for CloudFront custom domain"
  default     = null
}

variable "sbo_billing_tag" {
  type        = string
  description = "Value for the SBO_Billing tag"
  default     = "core_webapp"
  sensitive   = false
}

variable "domain_name" {
  type        = string
  description = "ALB domain name"
  default     = null
  sensitive   = false
}
