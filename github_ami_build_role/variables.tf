variable "account_id" {
  description = "AWS Account ID"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket name"
  type        = string
}

variable "github_organisation" {
  description = "GitHub Organization or User"
  type        = string
}

variable "repo_name" {
  description = "GitHub Repository Name"
  type        = string
}
