output "keycloak_private_subnets" {
  value = [aws_subnet.cs_subnet_a.id, aws_subnet.cs_subnet_b.id]
}

output "jupyterhub_private_subnet" {
  value = aws_subnet.cs_jupyterhub_subnet.id
}

output "secret_sharing_svc_private_subnet" {
  value = aws_subnet.cs_secret_sharing_svc_subnet.id
}

output "keycloak_subnet_cidr_a" {
  value = aws_subnet.cs_subnet_a.cidr_block
}

output "keycloak_subnet_cidr_b" {
  value = aws_subnet.cs_subnet_b.cidr_block
}
