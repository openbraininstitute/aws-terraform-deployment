variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "load_balancer_target_suffixes" {
  type = map(string)
}

variable "load_balancer_id" {
  type = string
}
