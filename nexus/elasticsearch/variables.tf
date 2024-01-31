variable "subnet_id" {
  type = string
}

variable "nexus_elasticsearch_instance_type" {
  type    = string
  default = "t3.small.search"
}

variable "nexus_elasticsearch_version" {
  type    = string
  default = "Elasticsearch_7.10"
}

variable "nexus_es_domain_name" {
  type    = string
  default = "nexus"
}

variable "subnet_security_group_id" {
  type        = string
  description = "security group applied to the resource which should describe how the resource can communicate inside the subnet"
}

variable "create_nexus_elasticsearch" {
  type    = bool
  default = true
}