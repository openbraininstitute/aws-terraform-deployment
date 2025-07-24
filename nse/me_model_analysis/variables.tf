variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "docker_image_url" {
  type = string
}

variable "amazon_linux_ecs_ami_id" {
  type = string
}

variable "account_id" {
  type = string
}

variable "route_table_id" {
  type = string
}

variable "deployment_env" {
  type        = string
  description = "The deployment environment, values: 'staging', 'production'"
}
