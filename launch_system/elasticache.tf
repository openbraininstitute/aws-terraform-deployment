resource "aws_security_group" "redis" {
  name        = "launch_system_redis_sg"
  description = "Security group for Redis instance"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow access from within VPC"
  }

  tags = merge(var.tags, { Name = "launch_system_redis" })
}

# Create ElastiCache subnet group with private subnets
resource "aws_elasticache_subnet_group" "redis" {
  name = "launch_system_redis_subnet_group"
  subnet_ids = [
    aws_subnet.trusted_a.id,
    aws_subnet.trusted_b.id,
  ]

  tags = merge(var.tags, { Name = "launch_system_redis" })
}

# Create ElastiCache cluster in the default VPC
resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "launch-system-redis-cluster" # only alphanumeric characters and hyphens
  engine               = "redis"
  node_type            = var.ec_node_type
  num_cache_nodes      = 1
  subnet_group_name    = aws_elasticache_subnet_group.redis.name
  parameter_group_name = "default.redis7"
  security_group_ids   = [aws_security_group.redis.id]
  apply_immediately    = true

  snapshot_retention_limit = 5

  tags = merge(var.tags, { Name = "launch_system_redis" })
}
