variable "db_instance_identifier" {
  type        = string
  description = "Identifier of the RDS PostgreSQL instance"
  sensitive   = false
}

variable "short_name" {
  type        = string
  description = "Short unique name, required for resources that need unique names"
  sensitive   = false
}

variable "cpu_utilization_high_threshold" {
  type        = number
  description = "Threshold percentage for high CPU utilization"
  sensitive   = false
  default     = 85
}

variable "freeable_memory_low_threshold" {
  type        = number
  description = "Threshold in bytes below which FreeableMemory triggers an alarm"
  sensitive   = false
  default     = 256000000 # 256 MB
}

variable "free_storage_space_low_threshold" {
  type        = number
  description = "Threshold in bytes below which FreeStorageSpace triggers an alarm"
  sensitive   = false
  default     = 5368709120 # 5 GB
}

variable "database_connections_high_threshold" {
  type        = number
  description = "Threshold for high number of database connections"
  sensitive   = false
  default     = 100
}

variable "read_latency_high_threshold" {
  type        = number
  description = "Threshold in seconds above which ReadLatency triggers an alarm"
  sensitive   = false
  default     = 0.05
}

variable "write_latency_high_threshold" {
  type        = number
  description = "Threshold in seconds above which WriteLatency triggers an alarm"
  sensitive   = false
  default     = 0.05
}

variable "swap_usage_high_threshold" {
  type        = number
  description = "Threshold in bytes above which SwapUsage triggers an alarm"
  sensitive   = false
  default     = 268435456 # 256 MB
}

variable "disk_queue_depth_high_threshold" {
  type        = number
  description = "Threshold above which DiskQueueDepth triggers an alarm"
  sensitive   = false
  default     = 64
}

variable "enable_cpu_credit_alarms" {
  type        = bool
  description = "Enable CPUCreditBalance and CPUSurplusCreditBalance alarms. Only applicable to burstable T-class instances (db.t3, db.t4g, etc.)."
  sensitive   = false
  default     = false
}

variable "cpu_credit_balance_low_threshold" {
  type        = number
  description = "Threshold below which CPUCreditBalance triggers an alarm"
  sensitive   = false
  default     = 50
}

variable "cpu_surplus_credit_balance_high_threshold" {
  type        = number
  description = "Threshold above which CPUSurplusCreditBalance triggers an alarm (indicates the instance is borrowing credits in unlimited mode)"
  sensitive   = false
  default     = 50
}
