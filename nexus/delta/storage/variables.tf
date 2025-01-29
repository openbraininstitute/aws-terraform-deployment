variable "subnet_id" {
  type        = string
  description = "ID of the subnet in which Delta should run"
}

variable "delta_efs_name" {
  type        = string
  description = "Unique name for the EFS associated with Delta. This is where the Delta config and the search config are stored and later mounted to the container."
}

variable "subnet_security_group_id" {
  type        = string
  description = "Security group applied to the resource which should describe how the resource can communicate inside the subnet."
}
