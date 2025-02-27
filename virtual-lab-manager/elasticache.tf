


resource "aws_security_group" "vlm_redis_sg" {
  name        = "vlm-redis-sg"
  description = "Security group for Redis instance for Virtual Lab Manager"

  vpc_id = var.vpc_id

  ingress {
    from_port   = 6379
    to_port     = 6379
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow access from within VPC"
  }
  tags = var.virtual_lab_manager_tags
}

resource "aws_elasticache_subnet_group" "vlm_redis_subnet_group" {
  name       = "vlm-redis-subnet-group"
  subnet_ids = [aws_subnet.virtual_lab_manager_a.id, aws_subnet.virtual_lab_manager_b.id]
  tags       = var.virtual_lab_manager_tags
}

resource "aws_elasticache_cluster" "vlm_redis_cluster" {
  cluster_id         = "vlm-redis-cluster"
  engine             = "redis"
  node_type          = "cache.t2.micro"
  num_cache_nodes    = 1
  subnet_group_name  = aws_elasticache_subnet_group.vlm_redis_subnet_group.name
  security_group_ids = [aws_security_group.vlm_redis_sg.id]
  apply_immediately  = true

  snapshot_retention_limit = 5
  tags                     = var.virtual_lab_manager_tags
}
