# Cluster-wide executor cache.
#
# Technology choice: EFS. The instances mount it once at boot (see user_data_executor.sh.tftpl),
# so tasks reach it through a host bind mount and pay no per-task attach cost -- measured in the
# sandbox at 8.5s startup with a bind mount versus 9.4s with a per-task EFS volume and 8.1s with
# no volume at all. It is POSIX, so nothing in the application has to learn an object API.
#
# It is a SEPARATE file system from public_launch_data rather than another access point on it:
# that file system is `bursting`, where throughput scales with stored size and is drawn from a
# shared credit balance. Cache traffic would compete with the 6.7 TB of public data for those
# credits. `elastic` bills per GiB transferred with no credit model, which suits a cache whose
# traffic is bursty and whose stored size is small.
#
# Contents must be ARCHIVES, one file per entry, unpacked onto the local cache by the consumer.
# EFS costs a round trip per metadata operation: measured, uv's cache tree (25,699 files, 1.19 GB)
# took 68-87s to install from EFS versus 18s from local disk, while a compiled-mechanism archive
# (1.9 MB, 3 files) packs and unpacks in well under a second. Store tarballs, never live trees.
resource "aws_efs_file_system" "executor_shared_cache" {
  creation_token = "launch-system-executor-shared-cache"

  # Derived artifacts only (wheels, compiled mechanisms). Encrypted because, unlike the
  # public data file system, this one is writable by tasks.
  encrypted       = true
  throughput_mode = "elastic"

  # Entries are content-addressed and cheap to rebuild, so let cold ones fall out rather than
  # paying standard-class storage forever. A reader promotes an entry back on access.
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

# Only the executor instances mount this, so the source is the instance security group rather
# than the VPC CIDR used by the public data file system.
resource "aws_vpc_security_group_ingress_rule" "executor_shared_cache_nfs" {
  security_group_id            = aws_security_group.executor_shared_cache.id
  description                  = "Allow NFS from executor instances"
  from_port                    = 2049
  to_port                      = 2049
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.executor_cpu_instance.id
}

# One mount target per executor subnet: a client must reach the target in its own availability
# zone, and cross-AZ NFS would add both latency and inter-AZ data charges.
resource "aws_efs_mount_target" "executor_shared_cache" {
  for_each = toset(local.executor_untrusted_subnet_ids)

  file_system_id  = aws_efs_file_system.executor_shared_cache.id
  subnet_id       = each.value
  security_groups = [aws_security_group.executor_shared_cache.id]
}
