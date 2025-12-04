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

variable "accounting_base_url" {
  type        = string
  description = "Accounting service base URL"
  sensitive   = false
}

variable "env_NEXTAUTH_URL" {
  type        = string
  sensitive   = false
  description = "NEXTAUTH_URL environment value for the webapp"
}
variable "env_KEYCLOAK_ISSUER" {
  type        = string
  sensitive   = false
  description = "KEYCLOAK_ISSUER environment value for the webapp"
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
