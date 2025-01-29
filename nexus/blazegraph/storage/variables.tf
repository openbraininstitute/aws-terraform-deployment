
variable "subnet_id" {
  type        = string
  description = "The ID of the subnet in which Blazegraph will be deployed."
}

variable "subnet_security_group_id" {
  type = string
}

# Blazegraph specific

variable "blazegraph_efs_name" {
  type        = string
  description = "The unique name of the EFS for Blazegraph"
}

variable "efs_blazegraph_data_dir" {
  type        = string
  default     = "/blazegraph-data-dir"
  description = "The EFS directory that will be mounted to /var/lib/blazegraph/data on the Blazegraph container. This is where the Blazegraph journal is located."
}
