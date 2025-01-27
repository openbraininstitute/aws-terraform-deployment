variable "aws_region" {
  type        = string
  description = "Deployment region. By default: us-east-1"
  default     = "us-east-1"
}

variable "elastic_vpc_endpoint_id" {
  type        = string
  description = "id of the vpc endpoint to use for the ES traffic filter"
}

variable "elastic_hosted_zone_name" {
  type        = string
  description = "name of the hosted zone in which the VPC endpoint exists"
}

variable "deployment_name" {
  type        = string
  description = "Name of the deployment in Elastic Cloud"
}

variable "elasticsearch_version" {
  type        = string
  description = "version of elasticsearch to use for the deployment"
}

variable "secret_recovery_window_in_days" {
  type        = number
  default     = 7
  description = "The recovery window for the secrets created by this module. It is useful mainly to set to 0 in sandbox so that the secrets are deleted instantly there."
}

/**
* Elasticsearch cluster
**/
variable "hot_node_size" {
  type        = string
  description = "sizing for the hot nodes of the cluster. In Elastic Cloud this is specified as a RAM value eg. 4g"
}

variable "hot_node_count" {
  type        = number
  description = "the number of hot nodes in the cluster, each in a different AZ"
  default     = 1
}

variable "aws_tags" {
  type = map(string)
}
