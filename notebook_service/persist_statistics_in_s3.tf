# The notebook service logs with awslogs to the CloudWatch log group.
# CloudWatch simply stores any stdout or stderr output of the notebook service as logs.
# The notebook service logs in json format. Some of those json messages have a field 'type' with
# value 'statistics' which should be kept for a longer period.
# A subscription filter in CloudWatch matches all json messages with that key and value present.
# A first role 'logs_to_firehose' is used by CloudWatch so the subscription filter is allowed to
# send the matching log events to firehose for processing.
# Firehose uses a second role 'firehose_role' which has the rights to store the
# final json message in S3. Firehose extracts unzips the events (cloudwatch sends compressed data)
# and extracts the year, month and day as metadata, which is used within the bucket for a hierarchy
# of files. The files contain the cloudwatch log events in json.

# An example log message:
# {
#   "time": "2025-09-24T17:35:49.580467+00:00",
#   "level": "INFO",
#   "name": "notebook_service.backend.eks.eks_backend",
#   "message": "Server d9593cb7aeca16163c09f5717aca8a17 was created for user driesverachtert",
#   "extra": {
#     "extra": {
#       "type": "statistics",
#       "notebook_name": "LFPy: passive single cell model with synapse -- plot LFP Heatmap",
#       "notebook_scale": "Cellular",
#       "github_path": "Cellular/emodels/lfpy_simulations/passive_emodel_synapses_heatmap/analysis_notebook.ipynb",
#       "github_user": "openbraininstitute",
#       "github_repo": "obi_platform_analysis_notebooks",
#       "github_branch": "main",
#       "vlab_id": "b3e4c5a8-39d1-4e5c-90f7-67d82e3d01c6",
#       "project_id": "d8f3a7b1-0e9c-43b5-92d1-1b3a4e5c9f02",
#       "user_id": "f9d1b2ea-84f0-4c21-8cde-5b0b1a2a3417",
#       "username": "driesverachtert"
#     }
#   },
#   "exception": null
# }

# The notebook service logs in json format. If the field .extra.extra.type equals to 'statistics',
# then the log entry should be handled by firehose.
resource "aws_cloudwatch_log_subscription_filter" "only_statistics" {
  name            = "notebook-service-filter-statistics"
  log_group_name  = aws_cloudwatch_log_group.ecs_task_logs.name
  destination_arn = aws_kinesis_firehose_delivery_stream.statistics.arn
  role_arn        = aws_iam_role.logs_to_firehose.arn
  filter_pattern  = "{ $.extra.extra.type = \"statistics\" }"
}

resource "aws_iam_role" "logs_to_firehose" {
  name_prefix = "notebook_service_logs_to_firehose_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "logs.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "logs_can_send_to_firehose" {
  name_prefix = "notebook_service_logs_can_send_to_firehose"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["firehose:PutRecord", "firehose:PutRecordBatch"],
      Resource = aws_kinesis_firehose_delivery_stream.statistics.arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "logs_can_send_to_firehose" {
  role       = aws_iam_role.logs_to_firehose.id
  policy_arn = aws_iam_policy.logs_can_send_to_firehose.arn
}

# Second part: the firehose kinesis datastream to alter the message and store it in S3
resource "aws_kinesis_firehose_delivery_stream" "statistics" {
  name        = "notebook-service-statistics-events"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.statistics.arn

    dynamic_partitioning_configuration {
      enabled = "true"
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose_logs.name
      log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
    }

    # Date-only prefix
    prefix              = "year=!{partitionKeyFromQuery:year}/month=!{partitionKeyFromQuery:month}/day=!{partitionKeyFromQuery:day}/"
    error_output_prefix = "failed/!{firehose:error-output-type}/!{timestamp:yyyy/MM/dd}/"

    # Keep file counts low at small volumes
    buffering_interval = 900 # seconds, max
    buffering_size     = 64  # MB

    compression_format = "GZIP"

    processing_configuration {
      enabled = true

      processors { type = "Decompression" }

      processors {
        type = "CloudWatchLogProcessing"

        parameters {
          parameter_name  = "DataMessageExtraction"
          parameter_value = "true"
        }
      }

      processors {
        type = "MetadataExtraction"

        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name = "MetadataExtractionQuery"
          parameter_value = trimspace(replace(<<-JQ
          {
            year:(.time | gsub("T.*+"; "")  | strptime("%Y-%m-%d") | strftime("%Y")),
            month:(.time | gsub("T.*+"; "")  | strptime("%Y-%m-%d") | strftime("%m")),
            day:(.time | gsub("T.*+"; "")  | strptime("%Y-%m-%d") | strftime("%d")),
            timestamp:.time
          }
          JQ
          , "/\n/", "  "))
        }
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "firehose_logs" {
  name_prefix       = "notebook_service_firehose"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Name = "notebook_service"
  }
}
resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "firehose_delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_logs.name
}

resource "aws_s3_bucket" "statistics" {
  bucket = "obi-notebook-service-statistics"
}

resource "aws_s3_bucket_ownership_controls" "statistics" {
  bucket = aws_s3_bucket.statistics.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "statistics" {
  bucket                  = aws_s3_bucket.statistics.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

resource "aws_iam_role" "firehose_role" {
  name = "firehose-s3-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = { Service = "firehose.amazonaws.com" },
        Action    = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "firehose_role_s3_access" {
  name_prefix = "notebook_service_firehose_s3_access"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:PutObject",
          "s3:ListBucketMultipartUploads"
        ],
        Resource = [
          aws_s3_bucket.statistics.arn,
          "${aws_s3_bucket.statistics.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_role_s3_access" {
  role       = aws_iam_role.firehose_role.id
  policy_arn = aws_iam_policy.firehose_role_s3_access.arn
}

resource "aws_iam_policy" "firehose_logging" {
  name_prefix = "notebook_service_firehose_logging"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ],
        Resource = [
          aws_cloudwatch_log_group.firehose_logs.arn,
          "${aws_cloudwatch_log_group.firehose_logs.arn}:*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_logging" {
  role       = aws_iam_role.firehose_role.id
  policy_arn = aws_iam_policy.firehose_logging.arn
}
