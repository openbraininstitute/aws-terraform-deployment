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
