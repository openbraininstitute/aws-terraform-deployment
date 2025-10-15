output "athena_data_catalog_name" {
  value       = awscc_athena_data_catalog.ro_access_to_db.name
  description = "The name of the created glue/athena data catalog, needed in athena queries"
}
