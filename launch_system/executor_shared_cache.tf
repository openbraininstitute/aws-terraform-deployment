# Shared executor cache (EFS, elastic). Separate from public_launch_data so cache I/O does not
# compete for bursting credits. Store archives only — live trees are slow on EFS metadata.
resource "aws_efs_file_system" "executor_shared_cache" {
  creation_token  = "launch-system-executor-shared-cache"
  encrypted       = true
  throughput_mode = "elastic"

  lifecycle_policy {
    transition_to_ia = "AFTER_30_DAYS"
  }

  lifecycle_policy {
    transition_to_primary_storage_class = "AFTER_1_ACCESS"
  }

  tags = merge(var.tags, { Name = "launch_system_executor_shared_cache" })
}

resource "aws_security_group" "executor_shared_cache" {
  name_prefix = "launch_system_executor_shared_cache"
  vpc_id      = var.vpc_id
  description = "Security group for the launch system executor shared cache EFS mount targets"

  tags = merge(var.tags, { Name = "launch_system_executor_shared_cache" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "executor_shared_cache_nfs" {
  security_group_id            = aws_security_group.executor_shared_cache.id
  description                  = "Allow NFS from executor instances"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.executor_cpu_instance.id
}

resource "aws_efs_mount_target" "executor_shared_cache" {
  for_each = toset(local.executor_untrusted_subnet_ids)

  file_system_id  = aws_efs_file_system.executor_shared_cache.id
  subnet_id       = each.value
  security_groups = [aws_security_group.executor_shared_cache.id]
}
