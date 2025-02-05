variable "user_name" {
  sensitive   = false
  type        = string
  description = "user name in IAM for the user that can use SES or Simple Email Service"
}
