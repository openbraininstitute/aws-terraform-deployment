variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "vpc_id" {
  type = string
}

variable "alb_listener_arn" {
  type = string
}

variable "alb_listener_rule_priority" {
  type = number
}

variable "base_path" {
  description = "Base path for the API"
  type        = string
}

variable "docker_image_url" {
  description = "Docker image for the bluenaas service"
  type        = string
  default     = "bluebrain/blue-naas-single-cell:latest"
}

variable "dockerhub_credentials_arn" {
  description = "ARN of the secret containing the DockerHub credentials"
  type        = string
}

variable "dockerhub_access_iam_policy_arn" {
  description = "ARN of IAM policy to access the secret containing the DockerHub credentials"
  type        = string
}

variable "internet_access_route_id" {
  type = string
}
