variable "sns_topic_arn" {
  description = "SNS topic ARN to fetch the notifications from"
  type        = string
}

variable "python_script_name" {
  description = "Name of the Python script to be executed"
  type        = string
  default     = "aws_json_log_sns_to_teams.py"
}

variable "handler" {
  description = "Handler for the Lambda function: normally scriptname dot functionname"
  type        = string
  default     = "aws_json_log_sns_to_teams.handle_log_event"
}

variable "python_runtime" {
  description = "Python runtime version"
  type        = string
  default     = "python3.13"
}

variable "unique_short_name" {
  description = "Unique name to be used in roles and so on"
  type        = string
}

variable "webhook_secret_arn" {
  description = "ARN of the secret containing the webhooks"
  type        = string
}

variable "webhook_secret_key" {
  description = "The key to use in the secret containing the webhooks"
  type        = string
}
