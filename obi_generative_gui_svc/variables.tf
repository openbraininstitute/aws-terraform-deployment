variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "private_alb_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "keycloak_url" {
  description = "Keycloak URL"
  type        = string
}

variable "docker_image_url" {
  description = "Docker image for the obi-generative-gui service"
  type        = string
}

variable "internet_access_route_id" {
  type = string
}
