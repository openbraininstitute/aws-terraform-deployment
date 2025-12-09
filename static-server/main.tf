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
    path                = "/sitemap.xml"
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
  bucket = var.static_content_bucket_name
  # TODO: Make sure force_destroy is not used for production deployments.
  force_destroy = true
}

resource "aws_s3_bucket_lifecycle_configuration" "static_storage" {
  bucket = aws_s3_bucket.static_storage.id
  rule {
    id     = "DeleteOldMultipartUploads"
    status = "Enabled"
    filter {}
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_metric" "static_storage_metrics" {
  bucket = aws_s3_bucket.static_storage.id
  name   = "EntireBucket"
}

resource "aws_s3_bucket_public_access_block" "static_storage" {
  bucket = aws_s3_bucket.static_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "static_storage" {
  bucket = aws_s3_bucket.static_storage.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "VPCEndpointAccess"
        Effect    = "Allow"
        Principal = "*"
        Action    = ["s3:GetObject"]
        Resource  = ["arn:aws:s3:::${var.static_content_bucket_name}/*"]
        Condition = {
          StringEquals = {
            "aws:SourceVpce" = aws_vpc_endpoint.s3_vpc_endpoint.id
          }
        }
      },
      {
        Sid    = "Write"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:user/cell_svc_bucket_user"
        }
        Action   = ["s3:*Object"]
        Resource = ["arn:aws:s3:::${var.static_content_bucket_name}/*"]
      },
      {
        Sid    = "List"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.account_id}:user/cell_svc_bucket_user"
        }
        Action   = ["s3:ListBucket"]
        Resource = ["arn:aws:s3:::${var.static_content_bucket_name}"]
      }
    ]
  })
}

locals {
  favicon = [
    {
      key          = "favicon.ico"
      source       = "${path.module}/favicon.ico"
      content_type = "image/vnd.microsoft.icon"
    }
  ]
  google_search_verification = {
    key          = "google62bf7fe0ad1621f2.html"
    source       = "${path.module}/google62bf7fe0ad1621f2.html"
    content_type = "text/html"
  }
  entraid_verification = {
    key = ".well-known/microsoft-identity-association.json"
    content = templatefile(
      "${path.module}/microsoft-identity-association.json.tftpl",
      {
        applicationId = var.domain_name == "www.openbraininstitute.org" ? "3c33faf6-86d5-4e53-afa6-d707d273bdf2" : "5345f792-e550-4ee2-896a-cb207e13d144"
      }
    )
    content_type = "text/json"
  }
  jupyterhub_requirements = {
    key          = "jupyterhub/requirements.txt"
    source       = "${path.module}/jupyterhub_requirements.txt"
    content_type = "text/plain"
  }
  sitemap_xml = {
    key          = "sitemap.xml"
    source       = "${path.module}/sitemap.xml"
    content_type = "text/xml"
  }
}

resource "aws_s3_object" "favicon" {
  count  = length(local.favicon)
  bucket = var.static_content_bucket_name

  key          = local.favicon[count.index].key
  source       = local.favicon[count.index].source
  content_type = local.favicon[count.index].content_type

  etag = filemd5(local.favicon[count.index].source)
}

resource "aws_s3_object" "google_search_verification" {
  bucket = var.static_content_bucket_name

  key          = local.google_search_verification.key
  source       = local.google_search_verification.source
  content_type = local.google_search_verification.content_type

  etag = filemd5(local.google_search_verification.source)
}

resource "aws_s3_object" "entraid_verification" {
  bucket = var.static_content_bucket_name

  key          = local.entraid_verification.key
  content      = local.entraid_verification.content
  content_type = local.entraid_verification.content_type
}

resource "aws_s3_object" "jupyterhub_requirements" {
  bucket = var.static_content_bucket_name

  key          = local.jupyterhub_requirements.key
  source       = local.jupyterhub_requirements.source
  content_type = local.jupyterhub_requirements.content_type
  etag         = filemd5(local.jupyterhub_requirements.source)
}

resource "aws_s3_object" "sitemap_xml" {
  bucket = var.static_content_bucket_name

  key          = local.sitemap_xml.key
  source       = local.sitemap_xml.source
  content_type = local.sitemap_xml.content_type

  etag = filemd5(local.sitemap_xml.source)
}

resource "aws_lb_listener_rule" "favicon" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority + 1

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
      values = ["/favicon.ico"]
    }
  }
}

resource "aws_lb_listener_rule" "google_search_verification" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority + 2

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
      values = ["/google62bf7fe0ad1621f2.html"]
    }
  }
}

resource "aws_lb_listener_rule" "sitemap_xml" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority + 3

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
      values = ["/sitemap.xml"]
    }
  }
}

resource "aws_lb_listener_rule" "entraid_verification" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_listener_rule_priority + 4

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
      values = ["/.well-known/microsoft-identity-association.json"]
    }
  }
}

resource "aws_lb_listener_rule" "jupyterhub_requirements" {
  listener_arn = var.alb_listener_arn
  priority     = 349 # higher prio. than /jupyterhub* rule

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
      values = ["/jupyterhub/requirements.txt"]
    }
  }
}
