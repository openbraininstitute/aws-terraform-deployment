variable "aws_region" {
  type        = string
  description = "Deployment region. By default: us-east-1"
  default     = "us-east-1"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_ids" {
  type        = list(string)
  description = "ID's of the subnets to use for the VPCE. Be aware they MUST be in the supported AZ (https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html#ec-traffic-filtering-vpc)"
}

variable "deployment_name" {
  type        = string
  description = "Name of the deployment in Elastic Cloud"
}

/**
* Route53
**/
variable "zone_name" {
  type        = string
  description = "Route53 zone name. By default: us-east-1"
  default     = "vpce.us-east-1.aws.elastic-cloud.com"
}

variable "record_ttl" {
  type        = string
  description = "TTL for the Route53 Record. By default: 300"
  default     = "300"
}

/**
* Private Link
**/
variable "service_name" {
  type        = string
  description = "The PrivateLink service name for your elastic cloud deployment. By default, us-east-1 (https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html)"
  default     = "com.amazonaws.vpce.us-east-1.vpce-svc-0e42e1e06ed010238"
}