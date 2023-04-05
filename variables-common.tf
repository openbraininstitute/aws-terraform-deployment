variable "aws_region" {
  type      = string
  default   = "us-east-1"
  sensitive = false
}

variable "epfl_cidr" {
  type        = string
  default     = "128.178.0.0/15"
  description = "CIDR of the network range used by EPFL"
  sensitive   = false
}

variable "sbo_https_test_hostname" {
  default     = "sbo-https-test.shapes-registry.org"
  type        = string
  description = "The default endpoint for the application load balancer"
  sensitive   = false
}

variable "core_webapp_hostname" {
  default     = "sbo-core-webapp.shapes-registry.org"
  type        = string
  description = "The hostname for the core webapp"
  sensitive   = false
}

variable "core_webapp_log_group_name" {
  default     = "core_webapp"
  type        = string
  description = "The log name within cloudwatch for the core webapp"
  sensitive   = false
}

variable "core_webapp_docker_image_url" {
  default     = "bluebrain/sbo-core-web-app"
  type        = string
  description = "docker image for the core webapp"
  sensitive   = false
}