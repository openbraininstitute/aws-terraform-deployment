# Locals
locals {
  ecs_cluster_arn    = module.ml_ecs_cluster.arn
  private_subnet_ids = [aws_subnet.ml_subnet_a.id, aws_subnet.ml_subnet_b.id]
}

# Variables
variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "account_id" {
  description = "AWS account id."
  type        = string
}

variable "vpc_id" {
  description = "ID of the vpc"
  type        = string
}

variable "is_production" {
  type = bool
}

variable "neuroagent_bucket_name" {
  type = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "route_table_private_subnets_id" {
  description = "ID of the route table for the private subnets"
}

variable "generic_private_alb_listener_arn" {
  description = "ARN of the Load Balancer Listener that the public NLB forwards to."
  type        = string
}

variable "generic_private_alb_security_group_id" {
  description = "ARN of the Load Balancer security group id."
  type        = string
}

variable "neuroagent_docker_image_url" {
  description = "URL of the ECR image of the neuroagent"
  type        = string
}

variable "ec_cluster_name" {
  description = "Name of the redis instance."
  default     = "redis-cluster"
}

variable "ec_engine" {
  description = "Engine of the cluster."
  default     = "redis"
}

variable "ec_node_type" {
  description = "Type of nodes for compute."
  default     = "cache.t4g.micro"
}

variable "ec_num_nodes" {
  default = 1
}

variable "ec_param_group" {
  description = "Group of parameters for redis"
  default     = "default.redis7"
}

variable "rds_engine" {
  description = "type of rds database."
  default     = "postgres"
}

variable "rds_version" {
  description = "version of the rds database."
  default     = "17"
}

variable "rds_instance_class" {
  description = "The instance class to use for the RDS instance."
  default     = "db.t4g.micro"
}

variable "rds_allocated_storage" {
  description = "The amount of storage to allocate for the RDS instance (in gigabytes)."
  type        = number
  default     = 20
}

variable "rds_user" {
  description = "Unsername of the rds instance."
  default     = "postgres"
}

variable "rds_port" {
  description = "Port of the rds instance."
  type        = string
  default     = "5432"
}

variable "rds_param_group" {
  description = "Group of parameters for the rds instance."
  default     = "postgres14"
}

variable "rds_storage_type" {
  description = "Type of storage (e.g. gp2 or gp3...)"
  default     = "gp2"

}

variable "rds_db_name" {
  description = "Name of the database."
  default     = "ml_postgres"

}

variable "github_repos" {
  description = "List of github repos that should be allowed to use ML's ECR"
  type        = list(string)
}

variable "github_oidc_provider_arn" {
  description = "ARN of the OIDC provider for GitHub"
  type        = string
}

variable "tags" {
  description = "tags of the resources."
  type        = map(string)
  default     = { SBO_Billing = "machinelearning" }
}

variable "ml_secrets_arn" {
  description = "ARN of the ML secrets manager"
  type        = string
}

variable "primary_domain" {
  type = string
}

variable "frontend_domain" {
  type        = string
  description = "Public-facing domain for the frontend (e.g. www.openbraininstitute.org)"
}

variable "obi_backup_plan" {
  type        = string
  description = "Name of the backup plan to use for production s3 buckets"
}

variable "keycloak_sbo_realm_url" {
  type        = string
  description = "URL of the Keycloak SBO realm"
}

variable "cors_origins" {
  type        = list(string)
  description = "List of origins allowed in the CORS header"
}
