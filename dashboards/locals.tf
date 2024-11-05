locals {
  private_load_balancer_suffix = join("/", slice(split("/", var.private_load_balancer_id), 1, 4))
}
