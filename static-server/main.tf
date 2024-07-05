data "aws_vpc" "provided_vpc" {
  id = var.vpc_id
}

locals {
  s3_vpc_endpoint_subnet_id_map = { for idx, subnet_id in tolist(var.public_subnet_ids) : idx => subnet_id }
}

resource "aws_security_group" "s3_vpc_endpoint_sg" {
  description = "Security group for S3 VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow HTTP traffic from the VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.provided_vpc.cidr_block]
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
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Interface"

  security_group_ids = [aws_security_group.s3_vpc_endpoint_sg.id]
  subnet_ids         = var.public_subnet_ids
}

resource "aws_lb_target_group" "static_data_tg" {
  name        = "s3-bucket-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

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
  bucket = var.domain_name
  # TODO: Make sure force_destroy is not used for production deployments.
  force_destroy = true
}

resource "aws_s3_bucket_metric" "static_storage_metrics" {
  bucket = aws_s3_bucket.static_storage.id
  name   = "EntireBucket"
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
          "Resource":["arn:aws:s3:::${var.domain_name}/*"]
        },
        {
          "Sid": "Write",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::671250183987:user/cell_svc_bucket_user"
          },
          "Action": ["s3:*Object"],
          "Resource":["arn:aws:s3:::${var.domain_name}/*"]
        },
        {
          "Sid": "List",
          "Effect": "Allow",
          "Principal": {
              "AWS": "arn:aws:iam::671250183987:user/cell_svc_bucket_user"
          },
          "Action": ["s3:ListBucket"],
          "Resource":["arn:aws:s3:::${var.domain_name}"]
        }
      ]
    }
  EOF
}

resource "aws_lb_listener_rule" "static_data" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.static_data_tg.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}

locals {
  coming_soon_page_files = [
    {
      key          = "static/coming-soon/index.html"
      source       = "${path.module}/coming-soon-page/index.html"
      content_type = "text/html"
    },
    {
      key          = "static/coming-soon/css/styles.css"
      source       = "${path.module}/coming-soon-page/styles.css"
      content_type = "text/css"
    },
    {
      key          = "static/coming-soon/css/background.jpg"
      source       = "${path.module}/coming-soon-page/background.jpg"
      content_type = "image/jpeg"
    }
  ]
}

resource "aws_s3_object" "coming_soon_page" {
  count  = length(local.coming_soon_page_files)
  bucket = var.domain_name

  key          = local.coming_soon_page_files[count.index].key
  source       = local.coming_soon_page_files[count.index].source
  content_type = local.coming_soon_page_files[count.index].content_type

  etag = filemd5(local.coming_soon_page_files[count.index].source)
}
