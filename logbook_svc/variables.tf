variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "internet_access_route_id" {
  description = "Shared private route table, which reaches the internet through the shared NAT Gateway."
  type        = string
}

variable "ecs_cidr_block_a" {
  type    = string
  default = "10.0.42.0/27"
}

variable "ecs_cidr_block_b" {
  type    = string
  default = "10.0.42.32/27"
}

variable "data_cidr_block_a" {
  type    = string
  default = "10.0.42.64/28"
}

variable "data_cidr_block_b" {
  type    = string
  default = "10.0.42.80/28"
}

variable "private_alb_listener_arn" {
  type = string
}

variable "private_alb_security_group_id" {
  description = "Security group of the shared private ALB, the only source allowed to reach the tasks."
  type        = string
}

variable "alb_listener_rule_priority" {
  description = "Priority of the logbook rule on the shared private ALB listener, unique on the listener."
  type        = number
}

variable "router_listener_rule_priority" {
  description = "Priority of the page router's rule on the shared private ALB listener, lower than alb_listener_rule_priority."
  type        = number
  # Checked in alb.tf, because a validation that reads another variable needs Terraform 1.9.
}

variable "router_image_url" {
  description = "Page router image (HAProxy, linux/arm64), from the same release as the server."
  type        = string

  validation {
    condition     = length(var.router_image_url) > 0
    error_message = "Set logbook_router_image_url before enabling the logbook server."
  }
}

variable "router_desired_count" {
  description = "Fewest page router tasks, the autoscaling floor."
  type        = number
}

variable "router_max_count" {
  description = "Most page router tasks autoscaling may run."
  type        = number
}

variable "bastion_cidr_block" {
  description = "Bastion host /32, allowed to reach Postgres for maintenance."
  type        = string
}

variable "base_path" {
  description = "Path prefix of every route (SERVER_BASE_PATH)."
  type        = string
}

variable "allowed_origins" {
  description = "Browser origins allowed by CORS and on the WebSocket upgrade."
  type        = list(string)
}

variable "trusted_proxy_cidr_blocks" {
  description = "Address ranges of the proxies in front of the server (SERVER_TRUSTED_PROXIES)."
  type        = list(string)

  validation {
    condition     = alltrue([for cidr in var.trusted_proxy_cidr_blocks : can(cidrhost(cidr, 0))])
    error_message = "Each trusted proxy entry must be a CIDR range, e.g. 10.0.2.144/28."
  }
}

variable "keycloak_issuer" {
  description = "Keycloak realm URL, the iss claim of the access tokens."
  type        = string
}

variable "entitycore_url" {
  description = "EntityCore API root, used for permission checks."
  type        = string
}

variable "image_url" {
  description = "Logbook server image (compiled Bun binary on distroless, linux/arm64)."
  type        = string

  validation {
    condition     = length(var.image_url) > 0
    error_message = "Set logbook_svc_image_url before enabling the logbook server."
  }
}

variable "task_size" {
  type = object({
    cpu    = any
    memory = any
  })

  description = "CPU and memory limit for ECS task (number or string format)"
}

variable "desired_count" {
  description = "Fewest server tasks, the autoscaling floor."
  type        = number

  # Limit: Cloud Map DNS shows the page router at most 8 tasks. Upgrade: a DiscoverInstances poller in the router.
  validation {
    condition     = var.desired_count <= 8
    error_message = "At most 8 tasks: past that the page router sees only 8."
  }
}

variable "server_timing_enabled" {
  description = "Send the Server-Timing header, which shows internal timings to clients."
  type        = bool
}

variable "max_count" {
  description = "Most server tasks autoscaling may run."
  type        = number

  # Checked against desired_count in autoscaling.tf, because a validation that reads another variable needs Terraform 1.9.
  validation {
    condition     = var.max_count <= 8
    error_message = "At most 8 tasks: past that the page router sees only 8."
  }
}

variable "scale_out_busy_pct" {
  description = "Average busy share (loop.busy.pct, 0 to 100) that adds a server task after 30 s."
  type        = number

  validation {
    condition     = var.scale_out_busy_pct > 0 && var.scale_out_busy_pct <= 100
    error_message = "scale_out_busy_pct is a share: above 0, at most 100."
  }
}

variable "scale_in_busy_pct" {
  description = "Average busy share that removes a server task after 15 minutes."
  type        = number

  validation {
    condition     = var.scale_in_busy_pct > 0 && var.scale_in_busy_pct <= 100
    error_message = "scale_in_busy_pct is a share: above 0, at most 100."
  }
}

variable "hand_off_busy_pct" {
  description = "Server env COLLABORATION_HAND_OFF_BUSY_PCT: one task's busy share at which it moves pages to other tasks (0 never)."
  type        = number

  validation {
    condition     = var.hand_off_busy_pct >= 0 && var.hand_off_busy_pct <= 100 && floor(var.hand_off_busy_pct) == var.hand_off_busy_pct
    error_message = "hand_off_busy_pct must be a whole number from 0 to 100."
  }
}

variable "shed_loop_delay_ms" {
  description = "Server env COLLABORATION_SHED_LOOP_DELAY_MS: event loop delay (ms) at which a task turns new work away (0 never)."
  type        = number

  validation {
    condition     = var.shed_loop_delay_ms >= 0 && var.shed_loop_delay_ms <= 60000 && floor(var.shed_loop_delay_ms) == var.shed_loop_delay_ms
    error_message = "shed_loop_delay_ms must be a whole number from 0 to 60000."
  }
}

variable "logbook_service_secrets_arn" {
  description = "Common secret of the service; its DB_PASS key is the RDS master password."
  type        = string
}

variable "db_name" {
  description = "Name of the database"
  type        = string
}

variable "db_username" {
  description = "Admin username for the database"
  type        = string
}

variable "db_instance_class" {
  description = "RDS instance class for the logbook database"
  type        = string
}

variable "db_multi_az" {
  description = "Standby in a second AZ with automatic failover."
  type        = bool
}

variable "redis_node_type" {
  description = "ElastiCache node type for the logbook Redis"
  type        = string
}

variable "obi_backup_plan" {
  description = "Name of the OBI backup plan"
  type        = string
}
