# Adapted from https://github.com/math280h/terraform-elastic-cloud-private-link-aws
# which is distributed under the MIT License
locals {
  ec_tags        = {
    Nexus       = "elastic",
    SBO_Billing = "nexus"
  }
}

resource "ec_deployment" "deployment" {
  name = var.deployment_name

  region                 = var.aws_region
  version                = var.elasticsearch_version
  deployment_template_id = "aws-general-purpose"

  traffic_filter = [ec_deployment_traffic_filter.deployment_filter.id]

  elasticsearch = {
    hot = {
      size        = var.hot_node_size
      zone_count  = var.hot_node_count
      autoscaling = {}
    }
  }

  kibana = {
    topology = {}
  }

  tags = local.ec_tags
}

resource "ec_deployment_traffic_filter" "deployment_filter" {
  name   = "Allow traffic from AWS VPC"
  region = var.aws_region
  type   = "vpce"

  rule {
    source = var.elastic_vpc_endpoint_id
  }
}