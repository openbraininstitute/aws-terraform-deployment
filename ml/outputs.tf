output "subnet_cidr_blocks" {
  description = "CIDR blocks of the ml (neuroagent) subnets"
  value = [
    aws_subnet.ml_subnet_a.cidr_block,
    aws_subnet.ml_subnet_b.cidr_block,
  ]
}
