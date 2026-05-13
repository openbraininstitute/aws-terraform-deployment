variable "unique_short_name" {
  description = "Short name which is used as prefix for certain resource names, to make them unique"
  type        = string
  sensitive   = false
}

variable "log_group_name" {
  description = "Log group name that should be filtered for json messages with level=error"
  type        = string
  sensitive   = false
}

variable "filter_pattern" {
  description = "Pattern to use to select the messages that have to end up in the SNS queue"
  type        = string
  sensitive   = false
  default     = "{ $.level = \"ERROR\" }"
}

variable "python_script_name" {
  description = "Name of the Python script to be executed"
  type        = string
  default     = "aws_json_error_logs_to_sns.py"
}

variable "handler" {
  description = "Handler for the Lambda function: normally scriptname dot functionname"
  type        = string
  default     = "aws_json_error_logs_to_sns.handle_log_event"
}

variable "python_runtime" {
  description = "Python runtime version"
  type        = string
  default     = "python3.13"
}

variable "region" {
  description = "AWS region"
  type        = string
}


variable "sbo_billing_tag" {
  type = string
}
