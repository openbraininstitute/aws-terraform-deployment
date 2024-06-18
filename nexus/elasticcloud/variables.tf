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
