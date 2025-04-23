variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "private_alb_listener_arn" {
  type = string
}

variable "root_path" {
  description = "Base path for the API"
  type        = string
}

variable "host_port" {
  description = "Internal host port"
  type        = number
}

variable "container_port" {
  description = "Container port"
  type        = number
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
