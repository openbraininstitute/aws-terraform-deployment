variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "internet_access_route_id" {
  description = "Shared private route table (routes 0.0.0.0/0 via the shared NAT Gateway)."
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
  description = "Security group of the shared private ALB; the only source allowed to reach the tasks."
  type        = string
}

variable "alb_listener_rule_priority" {
  description = "Priority of the logbook rule on the shared private ALB listener (unique on the listener)."
  type        = number
}

variable "router_listener_rule_priority" {
  description = "Priority of the page router's rule (page paths) on the shared private ALB listener: unique on the listener and lower than alb_listener_rule_priority, as the ALB tries the lowest number first."
  type        = number
  # Checked against alb_listener_rule_priority by a precondition on the router's listener rule
  # (alb.tf): a validation block that reads another variable needs Terraform 1.9.
}

variable "router_image_url" {
  description = "Image of the page router (log-book apps/router: HAProxy, linux/arm64), released with the server's version."
  type        = string

  validation {
    condition     = length(var.router_image_url) > 0
    error_message = "Set logbook_router_image_url in the environment's tfvars before enabling the logbook server."
  }
}

variable "router_desired_count" {
  description = "Fewest page router tasks (autoscaling's floor, autoscaling.tf). 2 keeps page traffic up while one router stops; every router builds the same ring."
  type        = number
}

variable "router_max_count" {
  description = "Most page router tasks autoscaling may run (autoscaling.tf). About 0.5 core of router per 100 busy pages (log-book deployment.md 6.8): 4 routers of 1 vCPU at the 60 % target carry about 500 busy pages, about what 8 server tasks carry."
  type        = number
}

variable "bastion_cidr_block" {
  description = "Bastion host /32, allowed to reach Postgres for maintenance."
  type        = string
}

variable "base_path" {
  description = "Path prefix of every route (SERVER_BASE_PATH); the ALB rule forwards it unchanged."
  type        = string
}

variable "allowed_origins" {
  description = "Browser origins allowed by CORS and on the WebSocket upgrade."
  type        = list(string)
}

variable "trusted_proxy_cidr_blocks" {
  description = "Address ranges of the proxies in front of the server (SERVER_TRUSTED_PROXIES): the private ALB subnets and the Azure Application Gateway subnets."
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
  description = "EntityCore API root, asked for permissions."
  type        = string
}

variable "image_url" {
  description = "Image of the logbook server (compiled Bun binary on distroless, linux/arm64)."
  type        = string

  validation {
    condition     = length(var.image_url) > 0
    error_message = "Set logbook_svc_image_url in the environment's tfvars before enabling the logbook server."
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
  description = "Fewest server tasks (autoscaling's floor, autoscaling.tf); after the first apply a change acts through the scaling target, not on the running count directly. 2 or more keeps live editing up while one task stops. At most 8: the page router finds the tasks in Cloud Map DNS, whose multivalue answer holds 8 records (router.tf)."
  type        = number

  # During a rolling deploy up to 2 x 8 tasks run for a moment; the router
  # then sees 8 of them, and the relay covers the pages that move.
  validation {
    condition     = var.desired_count <= 8
    error_message = "Past 8 tasks the page router sees only 8 (Cloud Map DNS): build the DiscoverInstances poller first (router.tf)."
  }
}

variable "server_timing_enabled" {
  description = "Send the Server-Timing header (shows internal timings to clients)."
  type        = bool
}

variable "max_count" {
  description = "Most server tasks autoscaling may run (autoscaling.tf); desired_count is the floor. At most 8, the Cloud Map ceiling of the page router (router.tf). Bound: 2 x max_count x 14 + max_count (a deploy at the most tasks) under the database's max_connections."
  type        = number

  # Checked against desired_count by a precondition on the scaling target
  # (autoscaling.tf): a validation that reads another variable needs Terraform 1.9.
  validation {
    condition     = var.max_count <= 8
    error_message = "Past 8 tasks the page router sees only 8 (Cloud Map DNS): build the DiscoverInstances poller first (router.tf)."
  }
}

variable "shed_loop_delay_ms" {
  description = "LIVE_SHED_LOOP_DELAY_MS of the server: the event loop's median delay (ms) at which a task refuses new work (load shedding). 0 never refuses."
  type        = number

  validation {
    condition     = var.shed_loop_delay_ms >= 0 && var.shed_loop_delay_ms <= 60000 && floor(var.shed_loop_delay_ms) == var.shed_loop_delay_ms
    error_message = "shed_loop_delay_ms must be a whole number from 0 to 60000 (the server's schema)."
  }
}

variable "logbook_service_secrets_arn" {
  description = "Common secret of the service (deployment-common); key DB_PASS is the RDS master password."
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
