locals {
  openscience_database_id = "nexus-openscience-db"
}

module "postgres_cluster_openscience" {
  source = "./postgres_cluster"

  providers = {
    aws = aws.nexus_openscience_postgres_tags
  }

  cluster_identifier              = local.openscience_database_id
  subnets_ids                     = module.networking.psql_subnets_ids
  security_group_id               = module.networking.main_subnet_sg_id
  instance_class                  = "db.m5d.xlarge"
  nexus_postgresql_engine_version = "16"
  nexus_secrets_arn               = var.nexus_secrets_arn
}

# Blazegraph instance dedicated to Blazegraph views
module "blazegraph_openscience_bg" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_openscience_blazegraph_tags
  }

  blazegraph_cpu              = 8192
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djava.awt.headless=true -Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-openscience-bg"
  blazegraph_efs_name      = "blazegraph-openscience-bg"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn
}

# Blazegraph instance dedicated to composite views
module "blazegraph_openscience_composite" {
  source = "./blazegraph"

  providers = {
    aws = aws.nexus_openscience_blazegraph_tags
  }

  blazegraph_cpu              = 8192
  blazegraph_memory           = 16384
  blazegraph_docker_image_url = "bluebrain/blazegraph-nexus:2.1.6-RC-21-jre"
  blazegraph_java_opts        = "-Djetty.maxFormContentSize=80000000 -XX:MaxDirectMemorySize=600m -Xms10g -Xmx10g -XX:+UseG1GC "

  blazegraph_instance_name = "blazegraph-openscience-composite"
  blazegraph_efs_name      = "blazegraph-openscience-composite"
  efs_blazegraph_data_dir  = "/bg-data"

  dockerhub_credentials_arn = module.iam.dockerhub_credentials_arn

  subnet_id                   = module.networking.subnet_id
  subnet_security_group_id    = module.networking.main_subnet_sg_id
  ecs_task_execution_role_arn = module.iam.nexus_ecs_task_execution_role_arn

  ecs_cluster_arn                          = aws_ecs_cluster.nexus_openscience.arn
  aws_service_discovery_http_namespace_arn = aws_service_discovery_http_namespace.nexus_openscience.arn
}
