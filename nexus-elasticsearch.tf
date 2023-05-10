# TODO not yet used I think, needs additional config in aws_opensearch_domain
resource "aws_cloudwatch_log_group" "nexus_es" {
  name              = "nexus_es"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "nexus_es"
    SBO_Billing = "nexus"
  }
}

resource "aws_security_group" "nexus_es" {
  name   = "nexus_es"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "Nexus Elastic Search"
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow access from within VPC"
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
    description = "allow access to the VPC"
  }
  tags = {
    SBO_Billing = "nexus"
  }
}

# TODO: figure out how to configure logging to nexus_es loggroup
resource "aws_opensearch_domain" "nexus_es" {
  count       = var.create_nexus_elasticsearch ? 1 : 0
  domain_name = var.nexus_es_domain_name

  # Note: if you switch between elasticsearch and opensearch, then also the instance type needs to be updated.
  engine_version = var.nexus_elasticsearch_version
  cluster_config {
    instance_count = 1
    instance_type  = var.nexus_elasticsearch_instance_type
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    throughput  = 125
  }

  vpc_options {
    subnet_ids = [
      aws_subnet.nexus_es_a.id,
    ]

    security_group_ids = [aws_security_group.nexus_es.id]
  }

  access_policies = <<CONFIG
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "es:*",
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.nexus_es_domain_name}/*"
        }
    ]
}
CONFIG

  tags = {
    Name        = "nexus_es"
    SBO_Billing = "nexus"
  }
  depends_on = [aws_iam_service_linked_role.os]
}

/*
Only one allowed per account? Use the one created in the ML deployment
resource "aws_iam_service_linked_role" "es" {
  aws_service_name = "es.amazonaws.com"
  description      = "Allows Amazon ES to manage AWS resources for a domain on your behalf."

  tags = {
    SBO_Billing = "nexus"
  }
}*/

