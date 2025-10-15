module "athena_ro_access_to_rds_db" {
  source = "../athena_ro_access_to_rds_db"

  secret_with_ro_db_credentials_arn = var.virtual_lab_manager_db_ro_secret_arn

  spill_bucket_name                   = "obi-athena-ro-spill-bucket-vlm-${var.aws_deployment_env}"
  spill_prefix                        = "spill"
  expire_spill_objects_after_num_days = 5

  rds_db_subnet_az = aws_subnet.virtual_lab_manager_a.availability_zone
  rds_db_subnet_id = aws_subnet.virtual_lab_manager_a.id
  vpc_id           = var.vpc_id

  db_host          = aws_db_instance.virtual_lab_manager.address # or aws_db_instance.virtual_lab_manager.endpoint ?
  db_port          = aws_db_instance.virtual_lab_manager.port
  db_database_name = var.virtual_lab_manager_postgres_db
  connection_type  = "POSTGRESQL"

  # used as prefix to make sure roles and so on are unique
  name_prefix                 = "vlm"
  data_catalog_version_number = 1
}
