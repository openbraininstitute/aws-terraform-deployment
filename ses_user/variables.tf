variable "user_name" {
  type        = string
  description = "IAM user name for the SES user"
}

variable "secret_arn" {
  type        = string
  description = "ARN of the Secrets Manager secret to store and rotate SES credentials"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}
