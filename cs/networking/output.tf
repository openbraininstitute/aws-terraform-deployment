output "keycloak_private_subnets" {
  value = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
}

data "aws_subnets" "all" {
  filter {
    name = "availability-zone"
    values = ["us-east-1a"]
  }
  filter {
    name = "vpc-id"
    values = ["vpc-08aa04757a326969b"]
  }
}

output "subnets" {
  value = data.aws_subnets.all.ids
}
