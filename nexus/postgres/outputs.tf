output "host" {
  value = aws_db_instance.nexusdb.address
}

output "second_host" {
  value = aws_db_instance.nexus_psql.address
}

output "host_read_replica" {
  value = aws_db_instance.nexusdb_read_replica.address
}