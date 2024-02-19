locals {
  domain = data.terraform_remote_state.common.outputs.primary_domain
}

locals {
  s3_vpc_endpoint_subnet_ids = [data.terraform_remote_state.common.outputs.public_a_subnet_id, data.terraform_remote_state.common.outputs.public_b_subnet_id]
}

locals {
  s3_vpc_endpoint_subnet_id_map = { for idx, subnet_id in tolist(local.s3_vpc_endpoint_subnet_ids) : idx => subnet_id }
}

resource "aws_security_group" "s3_vpc_endpoint_sg" {
  description = "Security group for S3 VPC endpoint"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  ingress {
    description = "Allow HTTP traffic from the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.common.outputs.vpc_cidr_block]
  }

  // TODO: limit to the S3 bucket for static content.
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] #tfsec:ignore:aws-ec2-no-public-egress-sgr
  }
}

resource "aws_vpc_endpoint" "s3_vpc_endpoint" {
  vpc_id            = data.terraform_remote_state.common.outputs.vpc_id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.s3_vpc_endpoint_sg.id]
  subnet_ids         = local.s3_vpc_endpoint_subnet_ids
}

resource "aws_lb_target_group" "static_data_tg" {
  name        = "s3-bucket-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = data.terraform_remote_state.common.outputs.vpc_id

  // TODO: improve the health check not to rely on a static file.
  health_check {
    path                = "/static/coming-soon/index.html"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 10
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

data "aws_network_interface" "static_data_s3_vpc_endpoint_eni" {
  for_each = local.s3_vpc_endpoint_subnet_id_map
  id       = tolist(aws_vpc_endpoint.s3_vpc_endpoint.network_interface_ids)[each.key]
}

resource "aws_lb_target_group_attachment" "s3_vpc_endpoint_eip" {
  for_each         = data.aws_network_interface.static_data_s3_vpc_endpoint_eni
  target_group_arn = aws_lb_target_group.static_data_tg.arn
  target_id        = each.value.private_ip

  depends_on = [data.aws_network_interface.static_data_s3_vpc_endpoint_eni]
}

#tfsec:ignore:aws-s3-enable-bucket-encryption
#tfsec:ignore:aws-s3-enable-bucket-logging
#tfsec:ignore:aws-s3-enable-versioning
#tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "static_storage" {
  bucket = local.domain
}

#tfsec:ignore:aws-s3-no-public-buckets
#tfsec:ignore:aws-s3-block-public-policy
resource "aws_s3_bucket_public_access_block" "static_storage" {
  bucket = aws_s3_bucket.static_storage.id

  block_public_acls  = true
  ignore_public_acls = true
}

resource "aws_s3_bucket_policy" "static_storage" {
  bucket = aws_s3_bucket.static_storage.id
  // TODO: limit bucket access to s3_vpc_endpoint
  policy = <<EOF
    {
      "Version":"2012-10-17",
      "Statement":[
        {
          "Sid":"AddPerm",
          "Effect":"Allow",
          "Principal": "*",
          "Action":["s3:GetObject"],
          "Resource":["arn:aws:s3:::${local.domain}/*"]
        }
      ]
    }
  EOF
}

resource "aws_lb_listener_rule" "static_data" {
  listener_arn = aws_lb_listener.sbo_https.arn
  priority     = 600

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static_data_tg.arn
  }

  condition {
    host_header {
      values = [local.domain]
    }
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}
