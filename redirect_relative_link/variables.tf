variable "from_path" {
  description = "Path component that has to match the incoming request"
  type        = string
}

variable "to_path" {
  description = "Path component for the redirection"
  type        = string
}

variable "to_query" {
  description = "Query component for the redirection without questionmark"
  type        = string
}

variable "priority" {
  description = "Priority of the ALB rule"
  type        = number
}

variable "primary_domain" {
  description = "Main domain name, used for redirect"
  type        = string
}

variable "alb_https_listener_arn" {
  description = "ARN of the https listener of the ALB"
  type        = string
}

