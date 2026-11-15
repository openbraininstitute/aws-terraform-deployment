# One node, no replica or snapshot: the server can rebuild everything in it.
# While Redis is down, open pages keep working and new page opens fail after 2 s.

resource "aws_elasticache_subnet_group" "logbook" {
  name       = "logbook-redis-subnet-group" # only alphanumeric characters and hyphens
  subnet_ids = [aws_subnet.logbook_data_a.id, aws_subnet.logbook_data_b.id]

  tags = {
    Name = "logbook_redis"
  }
}

resource "aws_elasticache_cluster" "logbook" {
  cluster_id           = "logbook-redis" # only alphanumeric characters and hyphens
  engine               = "redis"
  engine_version       = "7.1"
  node_type            = var.redis_node_type
  num_cache_nodes      = 1
  port                 = 6379
  subnet_group_name    = aws_elasticache_subnet_group.logbook.name
  parameter_group_name = "default.redis7"
  security_group_ids   = [aws_security_group.logbook_redis.id]

  # Node restarts wait for the maintenance window, so an apply never breaks page opens in working hours.
  apply_immediately  = false
  maintenance_window = "sun:05:00-sun:06:00"

  snapshot_retention_limit = 0 # nothing in it needs a backup, see above

  tags = {
    Name = "logbook_redis"
  }
}
