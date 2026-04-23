resource "aws_efs_file_system" "redis_data" {
  creation_token   = "grading-service-redis-data"
  performance_mode = "generalPurpose"
  encrypted        = true

  tags = merge({ Name = "grading_service_redis_data" }, var.tags)
}

resource "aws_efs_mount_target" "redis_data" {
  for_each = {
    "subnet_a" = aws_subnet.grading_service_a.id
    "subnet_b" = aws_subnet.grading_service_b.id
  }

  file_system_id  = aws_efs_file_system.redis_data.id
  subnet_id       = each.value
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "redis_data" {
  file_system_id = aws_efs_file_system.redis_data.id

  # GID and UID used in official Redis Docker image
  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/data/redis"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "0755"
    }
  }
}
