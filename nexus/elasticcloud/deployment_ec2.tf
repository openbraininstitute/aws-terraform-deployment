

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

  tags = merge(var.aws_tags, { "env" = var.is_production ? "production" : "staging", "ec_user" = "ec2" })
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

#tfsec:ignore:aws-ssm-secret-use-customer-key
resource "aws_secretsmanager_secret" "elastic_password_ec2" {
  name                    = "nexus_nexus-obp-elasticsearch_elastic_password_ec2"
  recovery_window_in_days = var.secret_recovery_window_in_days
}

# resource "aws_secretsmanager_secret_version" "elastic_password_ec2" {
#   secret_id = aws_secretsmanager_secret.elastic_password_ec2.id
#   secret_string = jsonencode({
#     username = "elastic",
#     password = ec_deployment.deployment_ec2.elasticsearch_password
#   })
# }
