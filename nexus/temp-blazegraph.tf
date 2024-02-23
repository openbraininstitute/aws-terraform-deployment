resource "aws_route53_record" "blazegrap_efs" {
  zone_id = var.domain_zone_id
  name    = "blazegraph-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.blazegraph.efs_blazegraph_dns_name]
}