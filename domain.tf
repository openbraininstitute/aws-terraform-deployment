# The domain that we use for the SBO POC: shapes-registry.org.
# Not attached to a VPC because it has to be a public network.
resource "aws_route53_zone" "domain" {
  name    = "shapes-registry.org"
  comment = "Test domain for SBO POC"

  tags = {
    SBO_Billing = "common"
  }
}
