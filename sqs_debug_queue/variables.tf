variable "unique_short_name" {
  description = "Short name which is used as prefix for certain resource names, to make them unique"
  type        = string
  sensitive   = false
}

variable "sns_topic_arn" {
  description = "ARN of the sns topic of which the events need to end up on the debug SQS queue"
  type        = string
  sensitive   = false
}

variable "message_retention_seconds" {
  description = "How long to keep the messages on the SQS queue in seconds"
  type        = number
  sensitive   = false
  default     = 3600 # 1 hour
}