module "athena_ro_access_to_rds_db" {
  source = "../athena_ro_access_to_rds_db"

  secret_with_ro_db_credentials_arn = var.accounting_db_ro_secret_arn

  spill_bucket_name                   = "obi-athena-ro-spill-bucket-acc-${var.aws_deployment_env}"
  spill_prefix                        = "spill"
  expire_spill_objects_after_num_days = 5

  rds_db_subnet_az = aws_subnet.accounting_db_a.availability_zone
  rds_db_subnet_id = aws_subnet.accounting_db_a.id
  vpc_id           = var.vpc_id

  db_host          = aws_db_instance.accounting.address
  db_port          = aws_db_instance.accounting.port
  db_database_name = var.db_name
  connection_type  = "POSTGRESQL"

  name_prefix = "acc" # used as prefix to make sure roles and so on are unique
}
