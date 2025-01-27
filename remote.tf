
data "terraform_remote_state" "common" {
  backend = "local"
  config = {
    path = "../aws-terraform-deployment-common/terraform.tfstate"
  }
}
