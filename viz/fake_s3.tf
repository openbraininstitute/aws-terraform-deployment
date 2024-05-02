resource "aws_s3_bucket" "isd" {
  count  = local.sandbox_resource_count
  bucket = "important-scientific-data"
  tags = {
    Name = "FAKES3"
  }
}

# Because aws_s3_bucket.isd has "count" set, its attributes must be accessed on specific instances. Can't use id
# resource "aws_s3_bucket_metric" "isd_metrics" {
#   bucket = aws_s3_bucket.isd.id
#   name   = "EntireBucket"
# }