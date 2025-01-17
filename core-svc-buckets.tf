# ---------------------------------------------------
# Bucket configuration
# ---------------------------------------------------

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "sbo-cell-svc-perf-test" {
  bucket = var.cell_svc_bucket_name
  tags = {
    SBO_Billing = "cell_svc"
  }
}

resource "aws_s3_object" "sbo-cell-svc-perf-test-directory" {
  count        = 1
  bucket       = aws_s3_bucket.sbo-cell-svc-perf-test.id
  key          = "bbp.cscs.ch"
  content_type = "application/x-directory"
  content      = ""
}

resource "aws_s3_bucket_metric" "sbo-cell-svc-perf-test-metrics" {
  bucket = aws_s3_bucket.sbo-cell-svc-perf-test.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_public_access_block" "sbo-cell-svc-perf-test" {
  bucket = aws_s3_bucket.sbo-cell-svc-perf-test.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "sbo-cell-svc-perf-test-versioning" {
  bucket = aws_s3_bucket.sbo-cell-svc-perf-test.id
  versioning_configuration {
    status = "Enabled"
  }
}

# ---------------------------------------------------
# User configuration
# ---------------------------------------------------
resource "aws_iam_user" "cell_svc_bucket_user" {
  name = "cell_svc_bucket_user"
  tags = {
    SBO_Billing = "cell_svc"
  }
}

# ---------------------------------------------------
# Group configuration
# ---------------------------------------------------
#tfsec:ignore:aws-iam-enforce-group-mfa
resource "aws_iam_group" "obp_nse_team" {
  name = "obp_nse_team"
}

resource "aws_iam_group_membership" "obp_nse_team" {
  name = "obp_nse-group-membership"

  users = [
    aws_iam_user.cell_svc_bucket_user.name
  ]

  group = aws_iam_group.obp_nse_team.name
}

# ---------------------------------------------------
# Cell SVC bucket policy configuration
# ---------------------------------------------------
#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "cell_svc_bucket_role_policy" {
  name   = "cell_svc_bucket_role_policy"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
        "Sid": "ListObjectsInBucket",
        "Effect": "Allow",
        "Action": ["s3:ListBucket"],
        "Resource": ["arn:aws:s3:::${var.cell_svc_bucket_name}"]
    },
    {
        "Sid": "AllObjectActions",
        "Effect": "Allow",
        "Action": "s3:*Object",
        "Resource": ["arn:aws:s3:::${var.cell_svc_bucket_name}/*"]
    }
  ]
}
EOF
  tags = {
    SBO_Billing = "cell_svc"
  }
}

# ---------------------------------------------------
# Attach policies to NSE group
# ---------------------------------------------------
resource "aws_iam_group_policy_attachment" "nse-policy-attach" {
  group      = aws_iam_group.obp_nse_team.name
  policy_arn = aws_iam_policy.cell_svc_bucket_role_policy.arn
}
