module "ml_sqs" {
  source = "terraform-aws-modules/sqs/aws"

  name = "ml-sqs"

  visibility_timeout_seconds = 120

  redrive_policy = {
    maxReceiveCount = 4
  }

  create_dlq                    = true
  dlq_name                      = "ml-dlq"
  dlq_message_retention_seconds = 1209600

  tags = var.tags
}

# tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-encryption-customer-key
#tfsec:ignore:aws-s3-enable-bucket-logging
resource "aws_s3_bucket" "ml_paper_bucket" {
  bucket = "ml-paper-bucket"

  tags = var.tags
}

resource "aws_s3_bucket_public_access_block" "ml_sqs_s3_restriction" {
  bucket = aws_s3_bucket.ml_paper_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "s3_versioning" {
  bucket = aws_s3_bucket.ml_paper_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_object" "ml_parser_folders" {
  for_each     = toset(var.sqs_etl_parser_list)
  bucket       = aws_s3_bucket.ml_paper_bucket.id
  key          = "${each.value}/"
  content_type = "application/x-directory"
}

resource "aws_vpc_endpoint" "sqs_endpoint" {
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.sqs"
  subnet_ids        = local.private_subnet_ids
  tags              = var.tags
  vpc_endpoint_type = "Interface"
}
