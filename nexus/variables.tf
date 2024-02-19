### Required Infrastructure Information

variable "aws_region" {
  type = string
}

variable "aws_account_id" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "dockerhub_access_iam_policy_arn" {
  type = string
}

variable "dockerhub_credentials_arn" {
  type = string
}

variable "nat_gateway_id" {
  type = string
}

variable "domain_zone_id" {
  type = string
}

variable "private_alb_listener_9999_arn" {
  type = string
}

variable "private_alb_dns_name" {
  type = string
}

variable "allowed_source_ip_cidr_blocks" {
  type = list(string)
}

variable "aws_lb_listener_sbo_https_arn" {
  type = string
}

variable "aws_lb_alb_dns_name" {
  type = string
}

# TODO: This is currently an implicit dependency. See `elasticsearch/domain.tf` and get rid of this
#variable "aws_iam_service_linked_role_depends_on" {
#  type        = string
#  description = "Dependency. The role that allows Amazon ES to manage AWS resources for you. This was shared from a role defined in ML."
#}

### Nexus Delta ###

variable "nexus_delta_hostname" {
  type      = string
  default   = "sbo-nexus-delta.shapes-registry.org"
  sensitive = false
}

### Nexus Storage Service ###

variable "amazon_linux_ecs_ami_id" {
  type = string
}

### Nexus Fusion ###

variable "nexus_fusion_hostname" {
  default   = "sbo-nexus-fusion.shapes-registry.org"
  type      = string
  sensitive = false
}

variable "nexus_fusion_docker_image_url" {
  default   = "bluebrain/nexus-web:1.9.9"
  sensitive = false
  type      = string
}

### Nexus Blazegraph ###

variable "private_blazegraph_hostname" {
  default     = "private-alb-blazegraph.shapes-registry.org"
  type        = string
  description = "Hostname at which the blazegraph containers can be reached via the private ALB"
  sensitive   = false
}

### Switches

variable "nexus_storage_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for Nexus Storage Service"
}

variable "nexus_fusion_ecs_number_of_containers" {
  type        = number
  default     = 1
  sensitive   = false
  description = "Number of containers for nexus fusion"
}
