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

variable "paper_bucket_name" {
  type = string
}

variable "vpc_cidr_block" {
  description = "CIDR block of the vpc"
  type        = string
}

variable "route_table_private_subnets_id" {
  description = "ID of the route table for the private subnets"
}

variable "private_alb_listener_arn" {
  description = "ARN of the Load Balancer Listener on Private subnets."
  type        = string
}

variable "generic_private_alb_listener_arn" {
  description = "ARN of the Load Balancer Listener that the public NLB forwards to."
  type        = string
}

variable "generic_private_alb_security_group_id" {
  description = "ARN of the Load Balancer security group id."
  type        = string
}

variable "backend_image_tag" {
  description = "Url of the docker image to use in the ECS container for the backend (format repo:tag)"
  type        = string
}

variable "etl_image_tag" {
  description = "Url of the docker image to use in the ECS container for etl (format repo:tag)"
  type        = string
}

variable "agent_image_tag" {
  description = "Url of the ECR imageof the agent (format repo:tag)"
  type        = string
}

variable "grobid_image_url" {
  description = "Url of the docker image to use in the ECS container for grobid (format repo:tag)"
  type        = string
}

variable "dockerhub_credentials_arn" {
  description = "arn of the credentials to the dockerhub instance."
  type        = string
}

variable "private_alb_security_group_id" {
  description = "ID of the security group attached to the private load balancer."
  type        = string
}

variable "os_domain_name" {
  description = "Name of the OS instance"
  type        = string
  default     = "ml-os"

}

variable "os_version" {
  description = "Version of the Opensearch cluster"
  type        = string
  default     = "OpenSearch_2.11"
}

variable "os_node_number" {
  description = "Number of nodes of the Opensearch cluster."
  type        = number
  default     = 4
}

variable "os_instance_type" {
  description = "Type of opensearch instance"
  type        = string
  default     = "t3.medium.search"
}

variable "os_ebs_volume" {
  description = "Storage size per node. Depends on the instance type"
  type        = number
  default     = 200
}

variable "os_ebs_throughput" {
  description = "Trhoughput of the gp3 ebs volume."
  type        = number
  default     = 255
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

variable "sqs_etl_parser_list" {
  description = "List of parsers deployed behind the load balancer"
  type        = list(string)
  default     = ["jats_xml", "xocs_xml", "tei_xml", "grobid_pdf", "pubmed_xml"]
}

variable "private_alb_dns" {
  description = "DNS of the private loadbalancer."
  type        = string
}

variable "rds_engine" {
  description = "type of rds database."
  default     = "postgres"
}

variable "rds_version" {
  description = "version of the rds database."
  default     = "16.4"
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

variable "github_repos" {
  description = "List of github repos that should be allowed to use ML's ECR"
  type        = list(string)
}

variable "tags" {
  description = "tags of the resources."
  type        = map(string)
  default     = { SBO_Billing = "machinelearning" }
}

variable "bbp_dmz_cidr" {
  type = string
}

variable "readonly_access_policy_statement_part1" {
  description = "Policy for read-only permission pt2"
  type        = string
}

variable "readonly_access_policy_statement_part2" {
  description = "Policy for read-only permission pt2"
  type        = string
}

variable "aws_ssoadmin_instances_arns" {
  description = "ARN of the ssoadmin instances"
  type        = list(string)
}

variable "ml_secrets_arn" {
  description = "ARN of the ML secrets manager"
  type        = string
}

variable "nexus_domain_name" {
  type        = string
  description = "Nexus service domain name"
}
