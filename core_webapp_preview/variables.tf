variable "app_name" {
  type        = string
  description = "Name of the Amplify application"
}

variable "repository_url" {
  type        = string
  description = "GitHub repository URL"
}

variable "github_access_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token for repository access"
}

variable "default_branch" {
  type        = string
  description = "Default branch to deploy"
  default     = "main"
}

variable "domain_name" {
  type        = string
  description = "Custom domain name for the Amplify app"
}

variable "route53_zone_id" {
  type        = string
  description = "Route53 hosted zone ID for domain validation"
}

variable "api_origin" {
  type        = string
  description = "API origin URL"
}

variable "deployment_env" {
  type        = string
  description = "Deployment environment"
}

variable "keycloak_issuer" {
  type        = string
  description = "Keycloak issuer URL"
}

variable "sanity_dataset" {
  type        = string
  description = "Sanity dataset name"
}

variable "stripe_publishable_key" {
  type        = string
  description = "Stripe publishable key"
}

variable "secrets_arn" {
  type        = string
  description = "ARN of AWS Secrets Manager secret containing KEYCLOAK_CLIENT_ID, KEYCLOAK_CLIENT_SECRET, and NEXTAUTH_SECRET"
}

variable "github_oidc_provider_arn" {
  type        = string
  description = "ARN of the GitHub OIDC provider"
}

locals {
  github_repo = replace(var.repository_url, "https://github.com/", "")
}
