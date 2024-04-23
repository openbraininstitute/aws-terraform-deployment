variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "db_instance_class" {
  type = string
}

variable "private_subnets" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
  default = ["sg-0bce1689beefc31a5"]
}

# One private and one public
variable "alb_subnets" {
  type = list(string)
  default = ["subnet-0c252fa53effe774f", "subnet-0a3ee2ac2dd0da260"]
}

#Subnet for datasync task
variable "datasync_subnet_arn" {
  type = string
  default = "arn:aws:ec2:eu-central-1:992382665735:subnet/subnet-0c252fa53effe774f"
}


## Since EFS is in regional zone, needs to have mount target in each subnet - to be discussed
variable "efs_subnets" {
  type = list(string)
  default = ["subnet-0c252fa53effe774f", "subnet-061424940d42c2c22", "subnet-0a3ee2ac2dd0da260"]  
}
