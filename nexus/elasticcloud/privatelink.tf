data "aws_vpc" "provided_vpc" {
  id = var.vpc_id
}

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

  tags = {
    SBO_Billing = "nexus_es"
  }
}

resource "aws_vpc_endpoint" "nexus_es_vpc_ep" {
  service_name = var.service_name

  vpc_id            = var.vpc_id
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.nexus_es_sg.id]
  subnet_ids         = var.subnet_ids

  depends_on = [aws_security_group.nexus_es_sg]

  tags = {
    SBO_Billing = "nexus_es"
  }
}

resource "aws_route53_zone" "nexus_es_zone" {
  name = var.zone_name

  vpc {
    vpc_id = var.vpc_id
  }

  tags = {
    SBO_Billing = "nexus_es"
  }
}

resource "aws_route53_record" "nexus_es_record" {
  zone_id = aws_route53_zone.nexus_es_zone.zone_id

  name    = "*"
  type    = "CNAME"
  records = [lookup(aws_vpc_endpoint.nexus_es_vpc_ep.dns_entry[0], "dns_name")]

  ttl = var.record_ttl

  depends_on = [aws_route53_zone.nexus_es_zone]
}