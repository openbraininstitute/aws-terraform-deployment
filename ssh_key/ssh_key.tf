resource "aws_key_pair" "key" {
  key_name   = var.name
  public_key = var.public_key

  tags = {
    SBO_Billing = "common"
  }
}