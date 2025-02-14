output "keycloak_private_subnets" {
  value = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
}

output "jupyterhub_private_subnet" {
  value = aws_subnet.cs_jupyterhub_subnet.id
}
