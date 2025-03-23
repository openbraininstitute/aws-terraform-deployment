

resource "ec_deployment" "deployment_ec2" {
  provider = ec.ec2

  name = var.deployment_name_ec2

  region                 = var.aws_region
  version                = var.elasticsearch_version
  deployment_template_id = "aws-general-purpose"

  traffic_filter = [ec_deployment_traffic_filter.deployment_filter_ec2.id]

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

  tags = var.aws_tags
}

resource "ec_deployment_traffic_filter" "deployment_filter_ec2" {
  provider = ec.ec2

  name   = "Allow traffic from AWS VPC"
  region = var.aws_region
  type   = "vpce"

  rule {
    source = var.elastic_vpc_endpoint_id
  }
}