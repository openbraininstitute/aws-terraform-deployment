locals {
  infra_assets_bucket_name = trimprefix(var.sboinfrastructureassets_bucket_name, "s3://")
  projects_bucket_name     = trimprefix(var.hpc_resource_provisioner_sbo_nexusdata_bucket, "s3://")
  scratch_bucket_name      = trimprefix(var.hpc_resource_provisioner_scratch_bucket, "s3://")
}
resource "aws_s3_bucket" "sboinfrastructureassets" {
  bucket = local.infra_assets_bucket_name
}

resource "aws_s3_bucket" "projects" {
  bucket = local.projects_bucket_name
}

resource "aws_s3_bucket" "scratch" {
  bucket = local.scratch_bucket_name
}

resource "aws_s3_bucket_policy" "sboinfrastructureassets" {
  bucket = aws_s3_bucket.sboinfrastructureassets.id
  policy = templatefile("${path.module}/bucket_policy.tftpl", { "account_id" = var.account_id, "bucket_name" = local.infra_assets_bucket_name })
}

resource "aws_s3_bucket_policy" "projects" {
  bucket = aws_s3_bucket.projects.id
  policy = templatefile("${path.module}/bucket_policy.tftpl", { "account_id" = var.account_id, "bucket_name" = local.projects_bucket_name })
}

resource "aws_s3_bucket_policy" "scratch" {
  bucket = aws_s3_bucket.scratch.id
  policy = templatefile("${path.module}/bucket_policy.tftpl", { "account_id" = var.account_id, "bucket_name" = local.scratch_bucket_name })
}
