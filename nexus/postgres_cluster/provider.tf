terraform {
  required_providers {
    postgresql = {
      source = "cyrilgdn/postgresql"
    }
  }
}

provider "postgresql" {
  # Configuration options
  host     = aws_rds_cluster.nexus.endpoint
  port     = 5432
  username = aws_rds_cluster.nexus.master_username
  password = aws_rds_cluster.nexus.master_password
}
