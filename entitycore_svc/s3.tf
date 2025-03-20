resource "aws_s3_bucket" "entitycore" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "entitycore-storage"
  }
}

# Enable versioning
resource "aws_s3_bucket_versioning" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id
  versioning_configuration {
    status = "Disabled"
  }
}

# Enable server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "entitycore" {
  bucket = aws_s3_bucket.entitycore.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_s3_bucket_policy" "prevent_delete" {
  bucket = aws_s3_bucket.entitycore.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PreventDeleteBucketAndObjects"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteBucket",
          "s3:DeleteBucketPolicy"
        ]
        Resource = [
          aws_s3_bucket.entitycore.arn,
          "${aws_s3_bucket.entitycore.arn}/*"
        ]
      },
      {
        Sid       = "PreventLifecycleModification"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:PutLifecycleConfiguration"
        ]
        Resource = aws_s3_bucket.entitycore.arn
      }
    ]
  })
}
