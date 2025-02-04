output "keycloak_private_subnets" {
  value = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
}
