locals {
  load_balancer_suffix = join("/", slice(split("/", var.load_balancer_id), 1, 4))
}
