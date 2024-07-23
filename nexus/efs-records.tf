resource "aws_route53_record" "nexus_delta_efs" {
  zone_id = var.domain_zone_id
  name    = "nexus-delta-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.nexus_delta.efs_delta_dns_name]
}

resource "aws_route53_record" "blazegraph_main_efs" {
  zone_id = var.domain_zone_id
  name    = "blazegraph-main-efs.shapes-registry.org"
  type    = "CNAME"
  ttl     = 60
  records = [module.blazegraph_main.efs_blazegraph_dns_name]
}