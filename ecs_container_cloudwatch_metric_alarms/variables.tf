variable "ecs_cluster_name" {
  type        = string
  description = "Name of the ECS cluster"
  sensitive   = false
}

variable "ecs_service_name" {
  type        = string
  description = "Name of the ECS service within the ECS cluster"
  sensitive   = false
}

variable "ecs_task_definition_name" {
  type        = string
  description = "Name of the task definition"
  sensitive   = false
}

variable "short_name" {
  type        = string
  description = "Short unique name, required for resources that need unique names"
  sensitive   = false
}

variable "ecs_service_memory_high_threshold" {
  type        = number
  description = "Threshold for high memory usage at service level"
  sensitive   = false
  default     = 85
}

variable "ecs_container_names_memory_alarm" {
  type        = list(string)
  description = "List of container names within the task definition for which to create a ContainerMemoryUtilization alarm"
  sensitive   = false
  default     = []
}

variable "ecs_container_memory_high_threshold" {
  type        = number
  description = "Threshold for high memory usage at container level"
  sensitive   = false
  default     = 85
}

variable "ecs_task_memory_high_threshold" {
  type        = number
  description = "Threshold for high memory usage at task level"
  sensitive   = false
  default     = 85
}
