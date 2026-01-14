data "aws_vpc" "main" {
  id = var.vpc_id
}

data "aws_secretsmanager_secret" "db_ro_secret" {
  arn = var.secret_with_ro_db_credentials_arn
}

resource "aws_iam_role" "ro_access_to_db" {
  name = "${var.name_prefix}_ro_access_to_db"

  assume_role_policy = <<-EOT
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOT
}

resource "aws_iam_role_policy" "ro_access_to_db_policy" {
  name = "${var.name_prefix}-athena-rds-connector-policy"
  role = aws_iam_role.ro_access_to_db.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid      = "SpillBucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::${var.spill_bucket_name}", "arn:aws:s3:::${var.spill_bucket_name}/*"]
      },
      # Spill bucket objects
      {
        Sid    = "SpillObjectsRW"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:AbortMultipartUpload",
          "s3:ListBucketMultipartUploads"
        ]
        Resource = ["arn:aws:s3:::${var.spill_bucket_name}", "arn:aws:s3:::${var.spill_bucket_name}/*"]
      },
      # Secrets Manager: to fetch DB credentials
      {
        Effect   = "Allow",
        Action   = ["secretsmanager:GetSecretValue"],
        Resource = var.secret_with_ro_db_credentials_arn
      },

      # Glue: if you pass a Glue connection to the connector
      {
        Effect = "Allow",
        Action = [
          "glue:GetConnection",
          "glue:GetConnections"
        ],
        Resource = "*"
      },

      # EC2: VPC access for Lambda ENIs
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      },

      # CloudWatch Logs for Lambda execution
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_security_group" "lambda_sg" {
  name   = "${var.name_prefix}-db-access-via-athena-datasource"
  vpc_id = var.vpc_id

}

resource "aws_security_group_rule" "rds_ingress_to_lambda" {
  type              = "ingress"
  from_port         = 0
  to_port           = 32000
  protocol          = "-1"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = [data.aws_vpc.main.cidr_block]
  description       = "allow ingress all vpc"
}

resource "aws_security_group_rule" "rds_egress_from_lambda" {
  type              = "egress"
  from_port         = 0
  to_port           = 32000
  protocol          = "-1"
  security_group_id = aws_security_group.lambda_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "allow ingress all"
}

resource "aws_s3_bucket" "spill_bucket" {
  bucket = var.spill_bucket_name
}

resource "aws_s3_bucket_lifecycle_configuration" "spill_cleanup" {
  bucket = aws_s3_bucket.spill_bucket.id

  rule {
    id     = "expire-spill-objects"
    status = "Enabled"

    filter {
      prefix = var.spill_prefix
    }

    expiration {
      days = var.expire_spill_objects_after_num_days
    }

    # Clean up failed/incomplete multipart uploads under the prefix
    abort_incomplete_multipart_upload {
      days_after_initiation = 1
    }

    # Only applies if bucket versioning is enabled
    noncurrent_version_expiration {
      noncurrent_days = var.expire_spill_objects_after_num_days
    }
  }
}

resource "aws_s3_bucket_public_access_block" "spill" {
  bucket                  = aws_s3_bucket.spill_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enforce bucket-owner-only access (disables object ACLs)
resource "aws_s3_bucket_ownership_controls" "spill" {
  bucket = aws_s3_bucket.spill_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# from https://github.com/hashicorp/terraform-provider-aws/issues/41050
resource "awscc_athena_data_catalog" "ro_access_to_db" {
  name        = "${var.name_prefix}-ro-db-access-${var.data_catalog_version_number}"
  description = "Read-only access to the RDS database used by ${var.name_prefix}"
  type        = "FEDERATED"

  connection_type = var.connection_type

  parameters = {
    "lambda-role-arn" = aws_iam_role.ro_access_to_db.arn
    "connection-type" = var.connection_type

    "connection-properties" = jsonencode(
      {
        "host"                = var.db_host,
        "port"                = var.db_port,
        "database"            = var.db_database_name,
        "SecretArn"           = var.secret_with_ro_db_credentials_arn,
        "spill_bucket"        = aws_s3_bucket.spill_bucket.id,
        "spill_prefix"        = var.spill_prefix,
        "AvailabilityZone"    = var.rds_db_subnet_az,
        "SecurityGroupIdList" = [aws_security_group.lambda_sg.id],
        "SubnetId"            = var.rds_db_subnet_id
      }
    )
  }

  lifecycle {
    # Athena adds additional parameters after resource creation, so ignoring changes to not affect plan
    ignore_changes = [
      parameters
    ]
  }
  depends_on = [
    aws_iam_role.ro_access_to_db,
    aws_iam_role_policy.ro_access_to_db_policy,
    aws_security_group.lambda_sg,
    aws_s3_bucket.spill_bucket,
  ]
}
