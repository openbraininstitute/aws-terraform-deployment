output "keycloak_private_subnets" {
  value = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
}

data "aws_subnets" "all" {
  filter {
    name   = "availability-zone"
    values = ["${var.aws_region}a"]
  }
  filter {
    name   = "vpc-id"
    values = ["${var.vpc_id}"]
  }
}

output "subnets" {
  value = data.aws_subnets.all.ids
}
