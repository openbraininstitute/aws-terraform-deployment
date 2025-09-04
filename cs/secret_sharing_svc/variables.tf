data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

variable "vpc_id" {
  type = string
}

variable "private_alb_https_listener_arn" {
  type = string
}

variable "secret_sharing_svc_port" {
  type = number
}

variable "secret_sharing_svc_listener_rule_priority" {
  type = number
}

variable "secret_sharing_svc_hostname" {
  type = string
}

variable "secret_sharing_svc_subnet" {
  type = string
}

variable "secret_sharing_svc_task_size" {
  type = object({
    cpu    = number
    memory = number
  })
}
