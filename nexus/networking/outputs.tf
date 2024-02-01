output "subnet_id" {
  value = aws_subnet.nexus.id
}

output "main_subnet_sg_id" {
  value = aws_security_group.main_sg.id
}

output "psql_subnets_ids" {
  value = [aws_subnet.nexus_db_a.id, aws_subnet.nexus_db_b.id]
}