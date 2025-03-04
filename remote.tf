data "terraform_remote_state" "common" {
  backend = "s3"
  config = {
    bucket       = var.terraform_remote_state_bucket_name
    key          = "deployment-common/terraform.tfstate"
    region       = "us-east-1"
    use_lockfile = true
    encrypt      = true
  }
}
