resource "aws_cloudfront_origin_access_control" "core_webapp_oac" {
  name                              = "core-webapp-${var.key}-oac"
  description                       = "OAC for Core WebApp S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# default cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_default" {
  name        = "core-webapp-${var.key}-default-policy"
  comment     = "Cache policy for Core WebApp default behavior with CORS headers"
  default_ttl = 86400    # 1 day
  max_ttl     = 31536000 # 1 year
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin", "Access-Control-Request-Headers", "Access-Control-Request-Method"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# static assets cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_static" {
  name    = "core-webapp-${var.key}-static-policy"
  comment = "Cache policy for Core WebApp static assets"
  # this values can be discussed when we deploy in staging to get some insights
  default_ttl = 2592000 # 30 days
  max_ttl     = 2592000 # 30 days
  min_ttl     = 2592000 # 30 days

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# images cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_images" {
  name        = "core-webapp-${var.key}-images-policy"
  comment     = "Cache policy for Core WebApp images"
  default_ttl = 2592000  # 30 days
  max_ttl     = 31536000 # 1 year
  min_ttl     = 86400    # 1 day

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "none"
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "core_webapp_cdn" {
  enabled         = true
  is_ipv6_enabled = true
  // TODO: should we use a root object?
  // probably add another file to the bucket, so we can use a root object just for the show
  // default_root_object = "index.html"
  price_class = "PriceClass_100" # Use only North America and Europe

  aliases = var.cloudfront_aliases

  origin {
    domain_name              = aws_s3_bucket.core_webapp.bucket_domain_name
    origin_id                = "S3-${aws_s3_bucket.core_webapp.id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.core_webapp_oac.id
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp.id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_default.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "*/_next/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp.id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_static.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "*/public/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp.id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_images.id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  // TODO: should we use a blacklist?
  // as 
  // restriction_type = "blacklist"
  // locations        = ["RU", "IR", ...] 
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = var.cloudfront_aliases == null || length(var.cloudfront_aliases) == 0
    acm_certificate_arn            = var.cloudfront_certificate_arn
    ssl_support_method             = var.cloudfront_certificate_arn != null ? "sni-only" : null
    minimum_protocol_version       = var.cloudfront_certificate_arn != null ? "TLSv1.2_2021" : null
  }

  tags = {
    Name        = "core-webapp-${var.key}-cdn"
    SBO_Billing = "core_webapp"
  }
}
