variable "sns_topic_arn" {
  description = "SNS topic ARN to fetch the notifications from"
  type        = string
}

variable "python_script_name" {
  description = "Name of the Python script to be executed"
  type        = string
}

variable "python_function_name" {
  description = "Name of the Lambda function within the script"
  type        = string
}

variable "handler" {
  description = "Handler for the Lambda function: normally scriptname dot functionname"
  type        = string
}

variable "python_runtime" {
  description = "Python runtime version"
  type        = string
}

variable "unique_name" {
  description = "Unique name to be used in roles / secrets / ..."
  type        = string
}

variable "secret_recovery_window_in_days" {
  description = "Recovery window in days for the secret"
  type        = number
}