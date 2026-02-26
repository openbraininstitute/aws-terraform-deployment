variable "eventbridge_archive_name" {
  type        = string
  description = "The name of the EventBridge archive"
  sensitive   = false
}

variable "eventbridge_pattern_source" {
  type        = list(string)
  description = "The source of the EventBridge rule"
  sensitive   = false
}

variable "eventbridge_archive_description" {
  type        = string
  description = "The description of the EventBridge archive"
  sensitive   = false
}

variable "eventbridge_retention_days" {
  type        = number
  description = "The number of days to retain the EventBridge archive"
  sensitive   = false
}
