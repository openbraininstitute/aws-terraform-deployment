variable "management_account_id" {
  type        = string
  description = "the AWS account ID of the management/root account"
}

variable "delegated_idcenter_member_account_id" {
  type        = string
  description = "the AWS account ID which contains the delegated IAM Identity Center"
}
