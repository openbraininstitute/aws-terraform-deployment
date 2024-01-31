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
    subnet_ids         = [var.subnet_id]
    security_group_ids = [var.subnet_security_group_id]
  }

  access_policies = data.aws_iam_policy_document.domain_policy.json

  tags = {
    Name        = "nexus_es"
    SBO_Billing = "nexus"
  }
  depends_on = [aws_iam_service_linked_role.es_linked_role]
}

resource "aws_iam_service_linked_role" "es_linked_role" {
  aws_service_name = "es.amazonaws.com"
  description      = "Allows Amazon ES to manage AWS resources for a domain on your behalf."
}


data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "domain_policy" {
  statement {
    actions = ["es:*"]
    resources = [
      "arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.nexus_es_domain_name}/*"
    ]
    effect = "Allow"
    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}
