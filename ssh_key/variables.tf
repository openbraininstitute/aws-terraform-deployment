variable "name" {
  description = "The name of the ssh key"
  sensitive   = false
  type        = string
}
variable "public_key" {
  description = "The public key of the ssh key"
  sensitive   = false
  type        = string
}
