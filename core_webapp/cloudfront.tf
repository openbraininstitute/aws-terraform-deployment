resource "aws_cloudfront_origin_access_control" "core_webapp_oac" {
  count                             = var.key == "main" ? 1 : 0
  name                              = "core-webapp-${var.key}-oac"
  description                       = "OAC for Core WebApp S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# default cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_default" {
  count       = var.key == "main" ? 1 : 0
  name        = "core-webapp-${var.key}-default-policy"
  comment     = "Cache policy for Core WebApp default behavior with CORS headers"
  default_ttl = 86400   # 1 day
  max_ttl     = 2592000 # 1 month
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
  count   = var.key == "main" ? 1 : 0
  name    = "core-webapp-${var.key}-static-policy"
  comment = "Cache policy for Core WebApp static assets"
  # respect origin cache control headers instead of using fixed ttl
  default_ttl = 0      # use origin cache control headers (need to test if setting to 0 is the reason for passing the s3 cache control headers)
  max_ttl     = 604800 # 1 week
  min_ttl     = 0      # use origin cache control headers (need to test if setting to 0 is the reason for passing the s3 cache control headers)

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

resource "aws_cloudfront_response_headers_policy" "core_webapp_fonts_cors" {
  name = "core-webapp-${var.key}-fonts-cors"

  cors_config {
    access_control_allow_credentials = false
    access_control_allow_headers {
      items = ["*"]
    }
    access_control_allow_methods {
      items = ["GET", "HEAD", "OPTIONS"]
    }
    access_control_allow_origins {
      items = ["*"] # we can fix it to be per domain after testing "https://staging.openbraininstitute.org"
    }
    origin_override = true
  }
}

# fonts cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_fonts" {
  count       = var.key == "main" ? 1 : 0
  name        = "core-webapp-${var.key}-fonts-policy"
  comment     = "Cache policy for Core WebApp fonts with CORS headers"
  default_ttl = 15768000 # 6 months (fonts don't change often)
  max_ttl     = 15768000 # 6 months
  min_ttl     = 0        # use origin cache control headers (need to test if setting to 0 is the reason for passing the s3 cache control headers)


  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "none"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Origin"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# images cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_images" {
  count       = var.key == "main" ? 1 : 0
  name        = "core-webapp-${var.key}-images-policy"
  comment     = "Cache policy for Core WebApp images"
  default_ttl = 0       # use origin cache control headers (need to test if setting to 0 is the reason for passing the s3 cache control headers)
  max_ttl     = 2592000 # 1 month
  min_ttl     = 0       # use origin cache control headers (need to test if setting to 0 is the reason for passing the s3 cache control headers)


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

# next image optimization cache policy
resource "aws_cloudfront_cache_policy" "core_webapp_next_image" {
  count       = var.key == "main" ? 1 : 0
  name        = "core-webapp-${var.key}-next-image-policy"
  comment     = "Cache policy for Next.js image optimization"
  default_ttl = 86400 # 1 day
  max_ttl     = 86400 # 1 day
  min_ttl     = 0

  parameters_in_cache_key_and_forwarded_to_origin {
    enable_accept_encoding_brotli = true
    enable_accept_encoding_gzip   = true

    query_strings_config {
      query_string_behavior = "all"
    }

    headers_config {
      header_behavior = "whitelist"
      headers {
        items = ["Accept"]
      }
    }

    cookies_config {
      cookie_behavior = "none"
    }
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "core_webapp_cdn" {
  count           = var.key == "main" ? 1 : 0
  enabled         = true
  is_ipv6_enabled = true
  // TODO: should we use a root object?
  // probably add another file to the bucket, so we can use a root object just for the show
  // default_root_object = "index.html"
  price_class = "PriceClass_100" # Use only North America and Europe

  aliases = var.cloudfront_aliases

  origin {
    domain_name              = aws_s3_bucket.core_webapp[0].bucket_domain_name
    origin_id                = "S3-${aws_s3_bucket.core_webapp[0].id}"
    origin_access_control_id = aws_cloudfront_origin_access_control.core_webapp_oac[0].id
  }

  dynamic "origin" {
    for_each = var.key == "main" ? ["main"] : []
    content {
      domain_name = var.domain_name
      origin_id   = "ALB-${var.key}"
      custom_origin_config {
        http_port              = 80
        https_port             = 443
        origin_protocol_policy = "https-only"
        origin_ssl_protocols   = ["TLSv1.2", "TLSv1.3"]
      }
    }
  }

  default_cache_behavior {
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp[0].id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_default[0].id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  dynamic "ordered_cache_behavior" {
    for_each = var.key == "main" ? ["main"] : []
    content {
      path_pattern           = "/_next/image/*"
      allowed_methods        = ["GET", "HEAD"]
      cached_methods         = ["GET", "HEAD"]
      target_origin_id       = "ALB-${var.key}"
      cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_next_image[0].id
      compress               = true
      viewer_protocol_policy = "redirect-to-https"
    }
  }

  ordered_cache_behavior {
    path_pattern               = "/_next/static/media/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    target_origin_id           = "S3-${aws_s3_bucket.core_webapp[0].id}"
    cache_policy_id            = aws_cloudfront_cache_policy.core_webapp_fonts[0].id
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
    response_headers_policy_id = aws_cloudfront_response_headers_policy.core_webapp_fonts_cors.id
  }

  ordered_cache_behavior {
    path_pattern           = "/_next/static/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp[0].id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_static[0].id
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern           = "/public/*"
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${aws_s3_bucket.core_webapp[0].id}"
    cache_policy_id        = aws_cloudfront_cache_policy.core_webapp_images[0].id
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
