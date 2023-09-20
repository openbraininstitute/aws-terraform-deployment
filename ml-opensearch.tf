# TODO not yet used I think, needs additional config in aws_opensearch_domain
resource "aws_cloudwatch_log_group" "ml_opensearch" {
  name              = "ml_opensearch"
  skip_destroy      = false
  retention_in_days = 5

  kms_key_id = null #tfsec:ignore:aws-cloudwatch-log-group-customer-key

  tags = {
    Application = "ml_opensearch"
    SBO_Billing = "machinelearning"
  }
}

resource "aws_security_group" "ml_opensearch" {
  name   = "ml_opensearch"
  vpc_id = data.terraform_remote_state.common.outputs.vpc_id

  description = "Machine Learning OpenSearch"
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
    SBO_Billing = "machinelearning"
  }
}

# TODO: figure out how to configure logging to ml_es loggroup
resource "aws_opensearch_domain" "ml_opensearch" {
  count       = var.create_ml_opensearch ? 1 : 0
  domain_name = var.ml_os_domain_name

  # Note: if you switch between elasticsearch and opensearch, then also the instance type needs to be updated.
  engine_version = var.ml_opensearch_version
  cluster_config {
    instance_count = 1
    instance_type  = var.ml_opensearch_instance_type
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10
    throughput  = 125
  }

  vpc_options {
    subnet_ids = [
      aws_subnet.ml_os.id,
    ]

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
            "Resource": "arn:aws:es:${data.terraform_remote_state.common.outputs.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${var.ml_os_domain_name}/*"
        }
    ]
}
CONFIG

  tags = {
    Name        = "ml_os"
    SBO_Billing = "machinelearning"
  }
  depends_on = [aws_iam_service_linked_role.os]
}

resource "aws_iam_service_linked_role" "os" {
  aws_service_name = "es.amazonaws.com"
  description      = "Allows Amazon ES to manage AWS resources for a domain on your behalf."

  tags = {
    SBO_Billing = "machinelearning"
  }
}
