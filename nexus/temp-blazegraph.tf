resource "aws_route53_record" "private_blazegraph" {
  zone_id = var.domain_zone_id
  name    = var.private_blazegraph_hostname
  type    = "CNAME"
  ttl     = 60
  records = [var.private_alb_dns_name]
}

resource "aws_route53_record" "blazegrap_efs" {
  zone_id = var.domain_zone_id
  name    = "blazegraph-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.blazegraph.efs_blazegraph_dns_name]
}