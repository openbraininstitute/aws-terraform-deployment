variable "unique_name" {
  description = "Unique name used as a prefix for the Lambda, role, and schedule."
  type        = string
  default     = "github-ticket-digest"
}

variable "github_token_secret_arn" {
  description = "ARN of the Secrets Manager secret (JSON) holding the obiadministrator GitHub token. Created in the common deployment."
  type        = string
}

variable "github_token_secret_key" {
  description = "JSON key within the GitHub token secret holding the token value."
  type        = string
  default     = "github_token"
}

variable "teams_webhook_secret_arn" {
  description = "ARN of the shared Teams webhook Secrets Manager secret (JSON). Created in the common deployment."
  type        = string
}

variable "teams_webhook_secret_key" {
  description = "JSON key within the shared Teams webhook secret holding this digest's webhook URL."
  type        = string
  default     = "github_ticket_digest"
}

variable "github_org" {
  description = "GitHub organization to search for stale issues."
  type        = string
  default     = "openbraininstitute"
}

variable "project_number" {
  description = "If > 0, source items from this GitHub Projects v2 board via GraphQL (requires the token to have read:project). If 0, fall back to an org-wide REST issue search."
  type        = number
  default     = 10
}

variable "exclude_statuses" {
  description = "Project board 'Status' option names to exclude (project mode only)."
  type        = list(string)
  default     = []
}

variable "include_statuses" {
  description = "Project board 'Status' option names to keep (project mode only). If non-empty, only these statuses pass."
  type        = list(string)
  default     = ["To do", "In progress", "Blocked", "Code Review / In Preview"]
}

variable "labels" {
  description = "Only include items carrying all of these labels (GitHub ANDs them). Empty = no label filter."
  type        = list(string)
  default     = ["standup"]
}

variable "stale_days" {
  description = "An issue is considered stale after this many days without updates."
  type        = number
  default     = 7
}

variable "include_prs" {
  description = "Whether to include pull requests in the digest (in addition to issues)."
  type        = bool
  default     = false
}

variable "max_items" {
  description = "Maximum number of stale items to list in the Teams digest."
  type        = number
  default     = 100
}

variable "schedule_expression" {
  description = "EventBridge Scheduler expression that triggers the digest, interpreted in var.schedule_timezone. Default: Monday 09:00."
  type        = string
  default     = "cron(0 9 ? * MON *)"
}

variable "schedule_timezone" {
  description = "IANA timezone in which schedule_expression is evaluated. EventBridge Scheduler follows DST for named zones. Default: Europe/Zurich (CET/CEST)."
  type        = string
  default     = "Europe/Zurich"
}

variable "python_runtime" {
  description = "Python runtime version for the Lambda function."
  type        = string
  default     = "python3.13"
}

variable "log_retention_in_days" {
  description = "CloudWatch Logs retention for the Lambda log group."
  type        = number
  default     = 14
}

variable "lambda_timeout_seconds" {
  description = "Lambda function timeout in seconds."
  type        = number
  default     = 120
}

variable "tags" {
  description = "Tags applied to created resources."
  type        = map(string)
  default     = {}
}
