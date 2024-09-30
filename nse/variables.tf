variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "me_model_analysis_docker_image_url" {
  type = string
}

variable "amazon_linux_ecs_ami_id" {
  type = string
}

variable "route_table_id" {
  type = string
}
