variable "cluster_name" {
  type        = string
  description = "The name of the cluster the Nexus stack is running on."
  default     = "nexus_ecs_cluster"
}

variable "delta_service_name" {
  type        = string
  description = "The name of the delta service."
}

variable "database" {
  type        = string
  description = "The Nexus database."
}

variable "s3_bucket" {
  type        = string
  description = "The S3 bucket."
}

variable "blazegraph_service_name" {
  type        = string
  description = "The name of the blazegraph service."
}

variable "blazegraph_composite_service_name" {
  type        = string
  description = "The name of the blazegraph composite service."
}

variable "blazegraph_composite_log_group" {
  type        = string
  description = "The log group of the blazegraph composite service."
}

variable "fusion_service_name" {
  type        = string
  description = "The name of the fusion service."
}

variable "aws_region" {
  type        = string
  description = "The AWS region in which the resources will be created."
}

variable "account_id" {
  type        = string
  description = "The ID of the AWS Account in which all components will be deployed."
}
