resource "aws_security_group" "ml_opensearch" {
  name   = "ml_opensearch"
  vpc_id = var.vpc_id

  description = "Machine Learning OpenSearch"
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [var.vpc_cidr_block]
    description = "allow access from within VPC"
  }
  tags = var.tags
}

# TODO: figure out how to configure logging to ml_es loggroup
resource "aws_opensearch_domain" "ml_opensearch" {
  domain_name = var.os_domain_name

  # Note: if you switch between elasticsearch and opensearch, then also the instance type needs to be updated.
  engine_version = var.os_version

  cluster_config {
    instance_count = var.os_node_number
    instance_type  = var.os_instance_type
  }

  ebs_options {
    ebs_enabled = true
    volume_size = var.os_ebs_volume
    throughput  = var.os_ebs_throughput
  }

  vpc_options {
    subnet_ids         = [local.private_subnet_ids[0]]
    security_group_ids = [aws_security_group.ml_opensearch.id]
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.aws_region}:${var.account_id}:domain/${var.os_domain_name}/*"
        }
    ]
}
CONFIG

  depends_on = [aws_iam_service_linked_role.ml_os_linked_role]
  tags       = var.tags
}

resource "aws_iam_service_linked_role" "ml_os_linked_role" {
  aws_service_name = "es.amazonaws.com"
  description      = "Allows Amazon ES to manage AWS resources for a domain on your behalf."

  tags = var.tags
}
