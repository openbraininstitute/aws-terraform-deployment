module "ml_mwaa" {
  source = "aws-ia/mwaa/aws"

  name              = "ml-airflow"
  airflow_version   = var.airflow_version
  environment_class = var.airflow_instance_type


  vpc_id             = var.vpc_id
  private_subnet_ids = local.private_subnet_ids
  source_cidr        = [var.vpc_cidr_block]

  min_workers = var.airflow_min_worker
  max_workers = var.airflow_max_worker

  iam_role_additional_policies = {
    "os-policy" = aws_iam_policy.ml_os_mwaa_policy.arn
  }

  logging_configuration = {
    dag_processing_logs = {
      enabled   = true
      log_level = "INFO"
    }

    scheduler_logs = {
      enabled   = true
      log_level = "INFO"
    }

    task_logs = {
      enabled   = true
      log_level = "INFO"
    }

    webserver_logs = {
      enabled   = true
      log_level = "INFO"
    }

    worker_logs = {
      enabled   = true
      log_level = "INFO"
    }
  }

  airflow_configuration_options = {
    "core.load_default_connections" = "false"
    "core.load_examples"            = "false"
    "webserver.dag_default_view"    = "tree"
    "webserver.dag_orientation"     = "TB"
    "logging.logging_level"         = "INFO"
  }

  create_s3_bucket               = false
  source_bucket_arn              = aws_s3_bucket.ml_airflow_bucket.arn
  requirements_s3_path           = "requirements.txt"
  requirements_s3_object_version = aws_s3_object.ml_requirements.version_id
  dag_s3_path                    = "dags/"

  depends_on = [aws_s3_bucket.ml_airflow_bucket]

  tags = {
    Name        = "ml_mwaa"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_iam_policy" "ml_os_mwaa_policy" {
  name = "ml_os_mwaa_access"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "es:ESHttpGet",
          "es:ESHttpPut",
          "es:ESHttpPost",
          "es:ESHttpDelete",
          "es:ESHttpHead"
        ],
        "Resource" : "arn:aws:es:${var.aws_region}:${var.account_id}:domain/${var.os_domain_name}/*"
      }
    ]
    }
  )
}
#tfsec:ignore:aws-s3-enable-bucket-encryption tfsec:ignore:aws-s3-encryption-customer-key tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "ml_airflow_bucket" {
  bucket = "ml-airflow-bucket"

  force_destroy = true

  tags = {
    Name        = "ml_s3_bucket"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_s3_bucket_public_access_block" "ml_airflow_s3_access_block" {
  bucket = aws_s3_bucket.ml_airflow_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.ml_airflow_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_object" "ml_dags" {
  bucket = aws_s3_bucket.ml_airflow_bucket.id

  for_each = fileset("ml/airflow-data/dags", "*.py")
  key      = format("%s/%s", "dags", each.value)

  source       = "ml/airflow-data/dags/${each.value}"
  content_type = each.value
  etag         = filemd5("ml/airflow-data/dags/${each.value}")
}

resource "aws_s3_object" "ml_requirements" {
  bucket = aws_s3_bucket.ml_airflow_bucket.id
  key    = "requirements.txt"

  source       = "ml/airflow-data/requirements.txt"
  content_type = "requirements.txt"
  etag         = filemd5("ml/airflow-data/requirements.txt")
}
