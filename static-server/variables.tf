variable "aws_region" {
  description = "The AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "domain_name" {
  description = "The domain name for the static website"
  type        = string
}

variable "vpc_id" {
  description = "The VPC ID"
  type        = string
}

variable "public_subnet_ids" {
  description = "The list of public subnet IDs"
  type        = list(string)
}

variable "alb_listener_arn" {
  type        = string
  description = "ALB listener to which the listener rule should be added"
}

variable "alb_listener_rule_priority" {
  description = "Priority of the listener rule"
  type        = number
}
