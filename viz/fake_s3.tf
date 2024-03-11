resource "aws_s3_bucket" "isd" {
  count  = local.sandbox_resource_count
  bucket = "important-scientific-data"
  tags = {
    Name = "FAKES3"
  }
}