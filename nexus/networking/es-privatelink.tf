resource "aws_security_group" "nexus_es_sg" {
  name        = "nexus_es_private_link_sg"
  description = "Security group for Nexus Elastic Cloud deployment private link access"

  vpc_id = var.vpc_id

  ingress {
    description = "Allow HTTPS to elastic cloud deployment"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.provided_vpc.cidr_block]
  }
}

resource "aws_vpc_endpoint" "nexus_es_vpc_ep" {
  # The PrivateLink service name for your elastic cloud deployment.
  # (https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html#ec-private-link-service-names-aliases)
  service_name = "com.amazonaws.vpce.us-east-1.vpce-svc-0e42e1e06ed010238"

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.nexus_es_sg.id]
  subnet_ids         = [aws_subnet.nexus_b.id]
}

resource "aws_route53_zone" "nexus_es_zone" {
  # The PrivateLink zone name for your elastic cloud deployment.
  # (https://www.elastic.co/guide/en/cloud/current/ec-traffic-filtering-vpc.html#ec-private-link-service-names-aliases)
  name = "vpce.us-east-1.aws.elastic-cloud.com" # Route53 zone name

  vpc {
    vpc_id = var.vpc_id
  }
}

resource "aws_route53_record" "nexus_es_record" {
  zone_id = aws_route53_zone.nexus_es_zone.zone_id

  name    = "*"
  type    = "CNAME"
  records = [lookup(aws_vpc_endpoint.nexus_es_vpc_ep.dns_entry[0], "dns_name")]

  ttl = 300
}
