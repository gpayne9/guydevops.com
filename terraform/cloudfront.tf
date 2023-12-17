# Define an AWS CloudFront distribution resource
resource "aws_cloudfront_distribution" "guydevops_cf_dis" {
  # Define the origin settings for the CloudFront distribution
  origin {
    domain_name = aws_s3_bucket_website_configuration.guydevops-com_s3_bucket_website.website_endpoint
    origin_id   = "S3Origin"

    # Configure custom origin settings for an S3 bucket
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "http-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1.2"]
    }

    # Add a custom header for the origin
    custom_header {
      name  = "Referer"
      value = var.secret_header
    }
  }

  # Enable the CloudFront distribution
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  # Set aliases (alternate domain names) for the distribution
  aliases = ["guydevops.com"]

  # Configure the default cache behavior for the distribution
  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Configure an ordered cache behavior for the distribution
  ordered_cache_behavior {
    path_pattern           = "/*"
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods = ["GET", "HEAD", "OPTIONS"]
    cached_methods  = ["GET", "HEAD"]
    compress        = true

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  # Configure the SSL certificate and protocol settings for the distribution
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.guydevops_cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }

  # Configure restrictions for the distribution based on geo-location
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["US", "CA", "GB", "DE"]
    }
  }
}

# Define an AWS Route 53 record resource for the domain
resource "aws_route53_record" "guydevops_record" {
  name    = "guydevops.com"
  type    = "A"
  zone_id = data.aws_route53_zone.guydevops_zone.zone_id

  # Configure an alias for the Route 53 record pointing to the CloudFront distribution
  alias {
    name                   = aws_cloudfront_distribution.guydevops_cf_dis.domain_name
    zone_id                = aws_cloudfront_distribution.guydevops_cf_dis.hosted_zone_id
    evaluate_target_health = false
  }
}
