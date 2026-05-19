variable "access_point_subnet_ids" {
  type = list(string)
}

variable "aws_region" {
  type = string
}

variable "account_id" {
  type = string
}

variable "entitycore_internal_bucket" {
  type        = string
  description = "S3 bucket name in which entitycore data lives."
}

variable "entitycore_internal_region" {
  type        = string
  description = "S3 region name in which entitycore data lives."
}

variable "opendata_bucket" {
  type        = string
  description = "S3 bucket name in which open data lives."
}

variable "opendata_region" {
  type        = string
  description = "S3 region name in which open data lives."
}

variable "internal_public_data_mountpath" {
  type        = string
  description = "Path on which internal public data will be available in EFS"
}

variable "opendata_mountpath" {
  type        = string
  description = "Path on which opendata will be available in EFS"
}

variable "opendata_paths_list" {
  type        = string
  description = "File in which the paths to sync on opendata are listed, one per line"
}

variable "public_launch_data_efs_arn" {
  type        = string
  description = "ARN of the EFS for the public launch data"
}

variable "public_launch_efs_securitygroup_arn" {
  type        = string
  description = "ARN of the security group of the EFS for the public launch data"
}

variable "azure_blobstore_opendata_container_url" {
  type        = string
  description = "The URL to the container that will hold opendata"
}

variable "azure_blobstore_internal_public_data_container_url" {
  type        = string
  description = "The URL to the container that will hold internal public data"
}

variable "azure_blobstore_opendata_sas_token" {
  type        = string
  sensitive   = true
  description = "SAS token with write access to the opendata blobstore container"
}

variable "azure_blobstore_internal_public_data_sas_token" {
  type        = string
  sensitive   = true
  description = "SAS token with write access to the internal public data blobstore container"
}

variable "azure_datasync_agent_activation_key_uswest2" {
  type        = string
  sensitive   = true
  description = "Activation key for the AWS DataSync agent deployed on Azure"
}

variable "azure_datasync_agent_activation_key_useast1" {
  type        = string
  sensitive   = true
  description = "Activation key for the AWS DataSync agent deployed on Azure for the useast1 AWS region"
}

variable "azure_nfs_server_hostname" {
  type        = string
  description = "Hostname for the NFS share for opendata and internal_public_data"
}

variable "azure_nfs_opendata_path" {
  type        = string
  description = "NFS export path for opendata on azure"
}

variable "azure_nfs_internal_public_data_path" {
  type        = string
  description = "NFS export path for internal_public_data on azure"
}

variable "datasync_target_account" {
  type        = string
  default     = ""
  description = "Account to which datasync should sync entitycore data"
}

variable "destination_entitycore_internal_bucket" {
  type        = string
  default     = ""
  description = "Destination bucket in {var.datasync_target_account} to which entitycore data needs to be synced"
}
