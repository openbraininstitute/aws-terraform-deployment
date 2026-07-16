variable "user_name" {
  type = string
}

variable "allow_resource_actions" {
  type        = list(map(list(string)))
  description = "A list with resource / actions combinations to explicitly allow. Each combination is a map with keys `resources` and `allow_actions`, each key is a list of strings"
}

variable "extra_policies" {
  type        = list(string)
  description = "ARNs of extra policies to attach to the user"
  default     = []
}
