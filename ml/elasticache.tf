resource "aws_security_group" "ml_redis_sg" {
  name        = local.redis_security_group_name
  description = "Security group for Redis instance"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow access from within VPC"
  }
  tags = var.tags
}

# Create ElastiCache subnet group with private subnets
resource "aws_elasticache_subnet_group" "ml_redis_subnet_group" {
  name       = local.redis_subnet_group_name
  subnet_ids = local.private_subnet_ids
  tags       = var.tags
}

# Create ElastiCache cluster in the default VPC
resource "aws_elasticache_cluster" "ml_redis_cluster" {
  cluster_id           = local.elasticache_cluster_id
  engine               = var.ec_engine
  node_type            = var.ec_node_type
  num_cache_nodes      = var.ec_num_nodes
  subnet_group_name    = aws_elasticache_subnet_group.ml_redis_subnet_group.name
  parameter_group_name = var.ec_param_group
  security_group_ids   = [aws_security_group.ml_redis_sg.id]
  apply_immediately    = true

  snapshot_retention_limit = 5
  tags                     = var.tags

  lifecycle {
    ignore_changes = [tags]
  }
}
