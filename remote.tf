
data "terraform_remote_state" "common" {
  backend = "local"
  config = {
    path = "/Users/heeren/source/github/openbraininstitute/aws-terraform-deployment-common/terraform.tfstate"
  }
}
