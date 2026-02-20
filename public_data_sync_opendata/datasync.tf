locals {
  opendata_paths = trim(replace(file("${path.module}/${var.opendata_paths_list}"), "\n", "|"), "|")
}

resource "aws_iam_role" "datasync_s3_role" {
  name = "datasync-s3-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "datasync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "datasync_s3_policy" {
  name = "datasync-s3-policy"
  role = aws_iam_role.datasync_s3_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:AbortMultipartUpload",
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:ListMultipartUploadParts",
          "s3:PutObject",
          "s3:GetObjectVersion",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectTagging",
          "s3:PutObjectTagging"
        ]
        Resource = [
          "arn:aws:s3:::${var.entitycore_internal_bucket}",
          "arn:aws:s3:::${var.entitycore_internal_bucket}/*",
          "arn:aws:s3:::${var.opendata_bucket}",
          "arn:aws:s3:::${var.opendata_bucket}/*"
        ]
      }
    ]
  })
}

resource "aws_datasync_location_s3" "internal_source" {
  s3_bucket_arn = "arn:aws:s3:::${var.entitycore_internal_bucket}"
  subdirectory  = "/public"

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_location_s3" "opendata_source" {
  s3_bucket_arn = "arn:aws:s3:::${var.opendata_bucket}"
  subdirectory  = "/"
  provider      = aws.uswest2

  s3_config {
    bucket_access_role_arn = aws_iam_role.datasync_s3_role.arn
  }
}

resource "aws_datasync_location_efs" "internal_destination" {
  efs_file_system_arn = var.public_launch_data_efs_arn

  # When recreating, remove subdirectory and uncomment the next two lines
  # See https://github.com/openbraininstitute/prod-platform-architecture/issues/163
  subdirectory = var.internal_public_data_mountpath
  # in_transit_encryption = "TLS1_2"
  # access_point_arn      = aws_efs_access_point.internal_public_data_readonly.arn
  # #############

  ec2_config {
    security_group_arns = [var.public_launch_efs_securitygroup_arn]
    subnet_arn          = "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${var.access_point_subnet_ids[0]}"
  }
}

resource "aws_datasync_task" "internal_s3_to_efs" {
  destination_location_arn = aws_datasync_location_efs.internal_destination.arn
  source_location_arn      = aws_datasync_location_s3.internal_source.arn
  name                     = "s3-to-efs-sync"

  # When recreating, set atime, mtime, uid, gid to NONE
  # See https://github.com/openbraininstitute/prod-platform-architecture/issues/163
  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "INT_VALUE"
    gid                    = "INT_VALUE"
    # atime             = "NONE"
    # mtime             = "NONE"
    # uid               = "NONE"
    # gid               = "NONE"
    posix_permissions = "PRESERVE"
    preserve_devices  = "NONE"
    bytes_per_second  = -1 # unlimited
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }
}

resource "aws_datasync_location_efs" "opendata_destination" {
  efs_file_system_arn = var.public_launch_data_efs_arn

  # When recreating, remove subdirectory and uncomment the next two lines
  # See https://github.com/openbraininstitute/prod-platform-architecture/issues/163
  subdirectory = var.opendata_mountpath
  # in_transit_encryption = "TLS1_2"
  # access_point_arn      = aws_efs_access_point.open_public_data_readonly.arn
  # ###

  ec2_config {
    security_group_arns = [var.public_launch_efs_securitygroup_arn]
    subnet_arn          = "arn:aws:ec2:${var.aws_region}:${var.account_id}:subnet/${var.access_point_subnet_ids[0]}"
  }
}

resource "aws_datasync_task" "opendata_s3_to_efs" {
  destination_location_arn = aws_datasync_location_efs.opendata_destination.arn
  source_location_arn      = aws_datasync_location_s3.opendata_source.arn
  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = local.opendata_paths
  }

  provider = aws.uswest2

  name = "opendata-s3-to-efs-sync"

  # When recreating, set atime, mtime, uid, gid to NONE
  # See https://github.com/openbraininstitute/prod-platform-architecture/issues/163
  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "INT_VALUE"
    gid                    = "INT_VALUE"
    # atime             = "NONE"
    # mtime             = "NONE"
    # uid               = "NONE"
    # gid               = "NONE"
    posix_permissions = "PRESERVE"
    preserve_devices  = "NONE"
    bytes_per_second  = -1 # unlimited
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }
}

resource "aws_datasync_task" "opendata_s3_to_azure" {
  destination_location_arn = awscc_datasync_location_azure_blob.azure_blobstore_opendata.location_arn
  source_location_arn      = aws_datasync_location_s3.opendata_source.arn
  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = local.opendata_paths
  }

  provider = aws.uswest2

  name = "opendata-s3-to-azure-sync"

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "NONE"
    gid                    = "NONE"
    posix_permissions      = "NONE"
    preserve_devices       = "NONE"
    bytes_per_second       = -1 # unlimited
    object_tags            = "NONE"
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }

  task_mode = "ENHANCED"
}

resource "aws_datasync_task" "internal_s3_to_azure" {
  destination_location_arn = awscc_datasync_location_azure_blob.azure_blobstore_internal_public_data.location_arn
  source_location_arn      = aws_datasync_location_s3.internal_source.arn

  provider = aws.uswest2

  name = "internal-public-data-s3-to-azure-sync"

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "NONE"
    gid                    = "NONE"
    posix_permissions      = "NONE"
    preserve_devices       = "NONE"
    bytes_per_second       = -1 # unlimited
    object_tags            = "NONE"
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }

  task_mode = "ENHANCED"
}

resource "awscc_datasync_location_azure_blob" "azure_blobstore_opendata" {

  provider = awscc.uswest2

  azure_access_tier        = "HOT"
  azure_blob_container_url = var.azure_blobstore_opendata_container_url
  azure_blob_sas_configuration = {
    # When updating the token, delete the Task(s) that use(s) this Location as well as the Location - the property cannot be edited and terraform doesn't try to delete first
    azure_blob_sas_token = var.azure_blobstore_opendata_sas_token
  }
  azure_blob_type = "BLOCK"
}

resource "awscc_datasync_location_azure_blob" "azure_blobstore_internal_public_data" {

  provider = awscc.uswest2

  azure_access_tier        = "HOT"
  azure_blob_container_url = var.azure_blobstore_internal_public_data_container_url
  azure_blob_sas_configuration = {
    # When updating the token, delete the Task(s) that use(s) this Location as well as the Location - the property cannot be edited and terraform doesn't try to delete first
    azure_blob_sas_token = var.azure_blobstore_internal_public_data_sas_token
  }
  azure_blob_type = "BLOCK"
}

resource "aws_datasync_agent" "azure_agent_uswest2" {
  name           = "azure-agent"
  activation_key = var.azure_datasync_agent_activation_key_uswest2
  provider       = aws.uswest2
}

resource "aws_datasync_agent" "azure_agent_useast1" {
  name           = "azure-agent"
  activation_key = var.azure_datasync_agent_activation_key_useast1
}

resource "aws_datasync_location_nfs" "azure_opendata" {
  server_hostname = var.azure_nfs_server_hostname
  subdirectory    = var.azure_nfs_opendata_path

  provider = aws.uswest2

  on_prem_config {
    agent_arns = [aws_datasync_agent.azure_agent_uswest2.arn]
  }
}

resource "aws_datasync_location_nfs" "azure_internal_publicdata" {
  server_hostname = var.azure_nfs_server_hostname
  subdirectory    = var.azure_nfs_internal_public_data_path

  on_prem_config {
    agent_arns = [aws_datasync_agent.azure_agent_useast1.arn]
  }
}

resource "aws_datasync_task" "opendata_s3_to_azure_nfs" {
  destination_location_arn = aws_datasync_location_nfs.azure_opendata.arn
  source_location_arn      = aws_datasync_location_s3.opendata_source.arn

  provider = aws.uswest2

  includes {
    filter_type = "SIMPLE_PATTERN"
    value       = local.opendata_paths
  }


  name = "opendata-s3-to-azure-nfs-sync"

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "NONE"
    gid                    = "NONE"
    posix_permissions      = "NONE"
    preserve_devices       = "NONE"
    bytes_per_second       = -1 # unlimited
    object_tags            = "NONE"
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }

  task_mode = "BASIC"
}

resource "aws_datasync_task" "internal_s3_to_azure_nfs" {
  destination_location_arn = aws_datasync_location_nfs.azure_internal_publicdata.arn
  source_location_arn      = aws_datasync_location_s3.internal_source.arn

  name = "internal-public-data-s3-to-azure-nfs-sync"

  options {
    verify_mode            = "ONLY_FILES_TRANSFERRED"
    preserve_deleted_files = "REMOVE"
    atime                  = "BEST_EFFORT"
    mtime                  = "PRESERVE"
    uid                    = "NONE"
    gid                    = "NONE"
    posix_permissions      = "NONE"
    preserve_devices       = "NONE"
    bytes_per_second       = -1 # unlimited
    object_tags            = "NONE"
  }

  schedule {
    # apparently you can't have `*` in both day-of-month and day-of-week - one needs to be a ? instead
    # minute | hour | day of month | month | day of week | year
    schedule_expression = "cron(0 0 ? * * *)"
  }

  task_mode = "BASIC"
}
