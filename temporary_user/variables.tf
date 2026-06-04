variable "user_name" {
  type = string
}

variable "allow_actions" {
  type    = list(string)
  default = ["*"]
}

variable "allow_resources" {
  type    = list(string)
  default = ["*"]
}
