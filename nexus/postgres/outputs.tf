output "host" {
  value = aws_db_instance.nexusdb.address
}

output "second_host" {
  value = aws_db_instance.nexus_psql.address
}
