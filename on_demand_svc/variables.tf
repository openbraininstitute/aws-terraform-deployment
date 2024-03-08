variable "svc_name" {
  type        = string
  description = "Service name which will be used to identify related resources as well as a role prefix."
}
variable "aws_region" {
  type        = string
  description = "AWS region where the service will be deployed."
}
variable "vpc_id" {
  type        = string
  description = "AWS VPC where the service will be deployed."
}
variable "ec2_subnet_id" {
  type        = string
  description = "Subnet where the service EC2 components will be deployed."
}
variable "ec2_image_id" {
  type        = string
  description = "AMI for ec2 launch template."
}
variable "ecs_subnet_id" {
  type        = string
  description = "Subnet where the service ECS components will be deployed."
}
variable "dockerhub_creds_arn" {
  type        = string
  description = "Docker hub credentials secret ARN."
}
variable "account_id" {
  type        = string
  description = "AWS account id."
}
variable "svc_image" {
  type        = string
  description = "Docker image for the service."
}
variable "svc_bucket" {
  type        = string
  description = "S3 bucket name that will be used to mount vlab/proj."
}
variable "tags" {
  type        = map(string)
  description = "JSON schema for websocket incoming message validation."
}
